#!/bin/bash
LOG_FILE="/var/log/OCI-airflow-initialize.log"
log() { 
	echo "$(date) [${EXECNAME}]: $*" >> "${LOG_FILE}" 
}
block_volume_count=2
option_list=(all all_dbs async aws azure celery cloudant crypto devel devel_hadoop druid gcp github_enterprise google_auth hashicorp hdfs hive jdbc kerberos kubernetes ldap mssql mysql oracle password postgres presto qds rabbitmq redis samba slack ssh vertica)
airflow_options=`curl -L http://169.254.169.254/opc/v1/instance/metadata/airflow_options`
EXECNAME="TUNING"
log "->TUNING START"
sed -i.bak 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
setenforce 0
EXECNAME="NSCD"
log "->INSTALL"
yum install nscd -y >> $LOG_FILE
systemctl start nscd.service
EXECNAME="TUNING"
log "->OS"
echo never | tee -a /sys/kernel/mm/transparent_hugepage/enabled
echo "echo never | tee -a /sys/kernel/mm/transparent_hugepage/enabled" | tee -a /etc/rc.local
echo vm.swappiness=1 | tee -a /etc/sysctl.conf
echo 1 | tee /proc/sys/vm/swappiness
echo net.ipv4.tcp_timestamps=0 >> /etc/sysctl.conf
echo net.ipv4.tcp_sack=1 >> /etc/sysctl.conf
echo net.core.rmem_max=4194304 >> /etc/sysctl.conf
echo net.core.wmem_max=4194304 >> /etc/sysctl.conf
echo net.core.rmem_default=4194304 >> /etc/sysctl.conf
echo net.core.wmem_default=4194304 >> /etc/sysctl.conf
echo net.core.optmem_max=4194304 >> /etc/sysctl.conf
echo net.ipv4.tcp_rmem="4096 87380 4194304" >> /etc/sysctl.conf
echo net.ipv4.tcp_wmem="4096 65536 4194304" >> /etc/sysctl.conf
echo net.ipv4.tcp_low_latency=1 >> /etc/sysctl.conf
sed -i "s/defaults        1 1/defaults,noatime        0 0/" /etc/fstab
ulimit -n 262144
# Disk Setup Functions
vol_match() {
case $i in
        1) disk="oraclevdb";;
        2) disk="oraclevdc";;
        3) disk="oraclevdd";;
        4) disk="oraclevde";;
        5) disk="oraclevdf";;
        6) disk="oraclevdg";;
        7) disk="oraclevdh";;
        8) disk="oraclevdi";;
        9) disk="oraclevdj";;
        10) disk="oraclevdk";;
        11) disk="oraclevdl";;
        12) disk="oraclevdm";;
        13) disk="oraclevdn";;
        14) disk="oraclevdo";;
        15) disk="oraclevdp";;
        16) disk="oraclevdq";;
        17) disk="oraclevdr";;
        18) disk="oraclevds";;
        19) disk="oraclevdt";;
        20) disk="oraclevdu";;
        21) disk="oraclevdv";;
        22) disk="oraclevdw";;
        23) disk="oraclevdx";;
        24) disk="oraclevdy";;
        25) disk="oraclevdz";;
        26) disk="oraclevdab";;
        27) disk="oraclevdac";;
        28) disk="oraclevdad";;
        29) disk="oraclevdae";;
        30) disk="oraclevdaf";;
        31) disk="oraclevdag";;
esac
}
iscsi_detection() {
	iscsiadm -m discoverydb -D -t sendtargets -p 169.254.2.$i:3260 2>&1 2>/dev/null
	iscsi_chk=`echo -e $?`
	if [ $iscsi_chk = "0" ]; then
		iqn[${i}]=`iscsiadm -m discoverydb -D -t sendtargets -p 169.254.2.${i}:3260 | gawk '{print $2}'`
		log "-> Discovered volume $((i-1)) - IQN: ${iqn[${i}]}"
		continue
	else
		volume_count="${#iqn[@]}"
		log "--> Discovery Complete - ${#iqn[@]} volumes found"
		detection_done="1"
	fi
}
iscsi_setup() {
        log "-> ISCSI Volume Setup - Volume ${i} : IQN ${iqn[$n]}"
        iscsiadm -m node -o new -T ${iqn[$n]} -p 169.254.2.${n}:3260
        log "--> Volume ${iqn[$n]} added"
        iscsiadm -m node -o update -T ${iqn[$n]} -n node.startup -v automatic
        log "--> Volume ${iqn[$n]} startup set"
        iscsiadm -m node -T ${iqn[$n]} -p 169.254.2.${n}:3260 -l
        log "--> Volume ${iqn[$n]} done"
}
EXECNAME="DISK DETECTION"
log "->Begin Block Volume Detection Loop"
detection_flag="0"
while [ "$detection_flag" = "0" ]; do
        detection_done="0"
        log "-- Detecting Block Volumes --"
        for i in `seq 2 33`; do
                if [ $detection_done = "0" ]; then
			iscsi_detection
		fi
        done;
        if [ "$volume_count" != "$block_volume_count" ]; then
                log "-- Sanity Check Failed - $volume_count Volumes found, $block_volume_count expected.  Re-running --"
                sleep 15
                continue
	else
                log "-- Setup for ${#iqn[@]} Block Volumes --"
                for i in `seq 1 ${#iqn[@]}`; do
                        n=$((i+1))
                        iscsi_setup
                done;
                detection_flag="1"
        fi
done;

EXECNAME="DISK PROVISIONING"
local_mount () {
  target=$1
  log "-->Mounting /dev/$disk to ${target}"
  mkdir -p ${target}
  mount -o noatime,barrier=1 -t ext4 /dev/$disk ${target}
  UUID=`lsblk -no UUID /dev/$disk`
  if [ ! -z $UUID ]; then 
	  echo "UUID=$UUID   ${target}    ext4   defaults,noatime,discard,barrier=0 0 1" | tee -a /etc/fstab
  fi
}

block_mount () {
  target=$1
  log "-->Mounting /dev/oracleoci/$disk to ${target}"
  mkdir -p ${target}
  mount -o noatime,barrier=1 -t ext4 /dev/oracleoci/$disk ${target}
  UUID=`lsblk -no UUID /dev/oracleoci/$disk`
  if [ ! -z $UUID ]; then 
  	echo "UUID=$UUID   ${target}    ext4   defaults,_netdev,nofail,noatime,discard,barrier=0 0 2" | tee -a /etc/fstab
  fi
}
raid_disk_setup() {
sed -e 's/\s*\([\+0-9a-zA-Z]*\).*/\1/' << EOF | fdisk /dev/oracleoci/$disk
n
p
1


t
fd
w
EOF
}
EXECNAME="DISK SETUP"
log "->Checking for disks..."
dcount=0
for disk in `ls /dev/ | grep nvme | grep n1`; do
        log "-->Processing /dev/$disk"
        mke2fs -F -t ext4 -b 4096 -E lazy_itable_init=1 -O sparse_super,dir_index,extent,has_journal,uninit_bg -m1 /dev/$disk
	target="/data${dcount}"
        local_mount ${target}
        dcount=$((dcount+1))
done;
if [ ${#iqn[@]} -gt 0 ]; then
for i in `seq 1 ${#iqn[@]}`; do
        n=$((i+1))
        dsetup="0"
        while [ $dsetup = "0" ]; do
                vol_match
                log "-->Checking /dev/oracleoci/$disk"
                if [ -h /dev/oracleoci/$disk ]; then
                        case $disk in
				oraclevdb)
				mke2fs -F -t ext4 -b 4096 -E lazy_itable_init=1 -O sparse_super,dir_index,extent,has_journal,uninit_bg -m1 /dev/oracleoci/$disk
				target="/var/log/airflow"
				block_mount ${target}
				;;

				oraclevdc)
				mke2fs -F -t ext4 -b 4096 -E lazy_itable_init=1 -O sparse_super,dir_index,extent,has_journal,uninit_bg -m1 /dev/oracleoci/$disk
				target="/opt/airflow"
				block_mount ${target} 
				;;
                                
				*)
				continue
                                ;;
                        esac
                        /sbin/tune2fs -i0 -c0 /dev/oracleoci/$disk
			unset UUID
                        dsetup="1"
                else
                        log "--->${disk} not found, running ISCSI again."
                        log "-- Re-Running Detection & Setup Block Volumes --"
			detection_done="0"
			log "-- Detecting Block Volumes --"
			for i in `seq 2 33`; do
				if [ $detection_done = "0" ]; then
		                        iscsi_detection
                		fi
		        done;
			for i in `seq 1 ${#iqn[@]}`; do
				n=$((i+1))
	                        iscsi_setup
			done
                fi
        done;
done;
fi
EXECNAME="MySQL DB"
log "->Install"
wget http://repo.mysql.com/mysql-community-release-el7-5.noarch.rpm
rpm -ivh mysql-community-release-el7-5.noarch.rpm
yum install mysql-server mysql-community-devel gcc-x86_64-linux-gnu python36 python36-devel gcc-4.8.5-39.0.3.el7.x86_64 -y
log "->Tuning"
head -n -6 /etc/my.cnf >> /etc/my.cnf.new
mv /etc/my.cnf /etc/my.cnf.rpminstall
mv /etc/my.cnf.new /etc/my.cnf
echo -e "transaction_isolation = READ-COMMITTED\n\
read_buffer_size = 2M\n\
read_rnd_buffer_size = 16M\n\
sort_buffer_size = 8M\n\
join_buffer_size = 8M\n\
query_cache_size = 64M\n\
query_cache_limit = 8M\n\
query_cache_type = 1\n\
thread_stack = 256K\n\
thread_cache_size = 64\n\
max_connections = 700\n\
key_buffer_size = 32M\n\
max_allowed_packet = 32M\n\
log_bin=/var/lib/mysql/mysql_binary_log\n\
server_id=1\n\
binlog_format = mixed\n\
explicit_defaults_for_timestamp = 1\n\
\n\
# InnoDB Settings\n\
innodb_file_per_table = 1\n\
innodb_flush_log_at_trx_commit = 2\n\
innodb_log_buffer_size = 64M\n\
innodb_thread_concurrency = 8\n\
innodb_buffer_pool_size = 4G\n\
innodb_flush_method = O_DIRECT\n\
innodb_log_file_size = 512M\n\
innodb_large_prefix = 1\n\
\n\
[mysqld_safe]\n\
log-error=/var/log/mysqld.log
pid-file=/var/run/mysqld/mysqld.pid \n\
\n\
sql_mode=STRICT_ALL_TABLES\n\
" >> /etc/my.cnf
log "->Start"
systemctl enable mysqld
systemctl start mysqld
log "->Bootstrap Databases"
mysql -e "UPDATE mysql.user SET Password = PASSWORD('SOMEPASSWORD') WHERE User = 'root'"
mysql -e "DROP USER ''@'localhost'"
mysql -e "DROP USER ''@'$(hostname)'"
mysql -e "SET GLOBAL log_bin_trust_function_creators = 1"
mysql -e "CREATE DATABASE AIRFLOW"
mysql -e "GRANT ALL ON AIRFLOW.* TO 'airflow'@'localhost' IDENTIFIED BY 'airflow'"
mysql -e "FLUSH PRIVILEGES"
EXECNAME="AIRFLOW"
log "->Install"
yum install python-pip -y >> $LOG_FILE
python3 -m pip install --upgrade pip
export AIRFLOW_HOME="/opt/airflow"
if [ $airflow_options = "true" ]; then 
	for option in ${option_list[@]}; do
		option_check=`curl -L http://169.254.169.254/opc/v1/instance/metadata/${option}`
		log "->Airflow ${option} set to $option_check"
		if [ $option_check = "true" ]; then
			python3 -m pip install "apache-airflow[${OPTION}]" >> $LOG_FILE
		fi
	done;
else
	python3 -m pip install apache-airflow >> $LOG_FILE
fi
python3 -m pip install "apache-airflow[mysql]"
python3 -m pip install gunicorn==19.9.0
python3 -m pip install oci
log "->InitDB"
airflow initdb >> $LOG_FILE
log "->Configure MySQL connection"
sed -i 's/sqlite:\/\/\/\/opt\/airflow\/airflow.db/mysql:\/\/airflow:airflow@127.0.0.1\/AIRFLOW/g' /opt/airflow/airflow.cfg >> $LOG_FILE
log "->InitDB MySQL"
airflow initdb >> $LOG_FILE
log "->SystemD setup"
cat > /lib/systemd/system/airflow-webserver.service << EOF
#
# Licensed to the Apache Software Foundation (ASF) under one
# or more contributor license agreements.  See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership.  The ASF licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License.  You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.

[Unit]
Description=Airflow webserver daemon
After=network.target postgresql.service mysql.service redis.service rabbitmq-server.service
Wants=postgresql.service mysql.service redis.service rabbitmq-server.service

[Service]
EnvironmentFile=/etc/sysconfig/airflow
User=airflow
Group=airflow
Type=simple
ExecStart=/usr/local/bin/airflow webserver --pid /run/airflow/webserver.pid
Restart=on-failure
RestartSec=5s
PrivateTmp=true

[Install]
WantedBy=multi-user.target
EOF
cat > /lib/systemd/system/airflow-scheduler.service << EOF
#
# Licensed to the Apache Software Foundation (ASF) under one
# or more contributor license agreements.  See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership.  The ASF licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License.  You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.

[Unit]
Description=Airflow scheduler daemon
After=network.target postgresql.service mysql.service redis.service rabbitmq-server.service
Wants=postgresql.service mysql.service redis.service rabbitmq-server.service

[Service]
EnvironmentFile=/etc/sysconfig/airflow
User=airflow
Group=airflow
Type=simple
ExecStart=/usr/local/bin/airflow scheduler
Restart=always
RestartSec=5s

[Install]
WantedBy=multi-user.target
EOF
cat > /etc/sysconfig/airflow << EOF
#
# Licensed to the Apache Software Foundation (ASF) under one
# or more contributor license agreements.  See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership.  The ASF licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License.  You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.

# This file is the environment file for Airflow. Put this file in /etc/sysconfig/airflow per default
# configuration of the systemd unit files.
#
AIRFLOW_CONFIG=/opt/airflow/airflow.cfg
AIRFLOW_HOME=/opt/airflow/
EOF
mkdir -p /run/airflow
mkdir -p /opt/airflow/plugins/hooks
mkdir -p /opt/airflow/plugins/operators
mkdir -p /opt/airflow/plugins/sensors
mkdir -p /opt/airflow/dags
useradd -s /sbin/nologin airflow
chown -R airflow:airflow /run/airflow
log "->Download OCI Hooks & Operators"
wget https://raw.githubusercontent.com/oracle-quickstart/oci-airflow/master/scripts/plugins/hooks/oci_base.py -O /opt/airflow/plugins/hooks/oci_base.py
wget https://raw.githubusercontent.com/oracle-quickstart/oci-airflow/master/scripts/plugins/hooks/oci_object_storage.py -O /opt/airflow/plugins/hooks/oci_object_storage.py
wget https://raw.githubusercontent.com/oracle-quickstart/oci-airflow/master/scripts/plugins/hooks/oci_data_flow.py -O /opt/airflow/plugins/hooks/oci_data_flow.py
wget https://raw.githubusercontent.com/oracle-quickstart/oci-airflow/master/scripts/plugins/operators/oci_object_storage.py -O /opt/airflow/plugins/operators/oci_object_storage.py
wget https://raw.githubusercontent.com/oracle-quickstart/oci-airflow/master/scripts/plugins/operators/oci_data_flow.py -O /opt/airflow/plugins/operators/oci_data_flow.py
wget https://raw.githubusercontent.com/oracle-quickstart/oci-airflow/master/scripts/plugins/sensors/oci_object_storage.py -O /opt/airflow/plugins/sensors/oci_object_storage.py
wget https://raw.githubusercontent.com/oracle-quickstart/oci-airflow/master/scripts/dags/oci_simple_example.py -O /opt/airflow/dags/oci_simple_example.py
wget https://raw.githubusercontent.com/oracle-quickstart/oci-airflow/master/scripts/dags/oci_advanced_example.py -O /opt/airflow/dags/oci_advanced_example.py
wget https://raw.githubusercontent.com/oracle-quickstart/oci-airflow/master/scripts/custom/connection_form.js -O /usr/local/lib/python3.6/site-packages/airflow/www/static/connection_form.js
wget https://raw.githubusercontent.com/oracle-quickstart/oci-airflow/master/scripts/custom/connection.py -O /usr/local/lib/python3.6/site-packages/airflow/models/connection.py
wget https://raw.githubusercontent.com/oracle-quickstart/oci-airflow/master/scripts/custom/www_rbac_views.py -O /usr/local/lib/python3.6/site-packages/airflow/www_rbac/views.py
wget https://raw.githubusercontent.com/oracle-quickstart/oci-airflow/master/scripts/custom/www_views.py -O /usr/local/lib/python3.6/site-packages/airflow/www/views.py
chown -R airflow:airflow /opt/airflow
log "->Start Scheduler"
systemctl start airflow-scheduler
log "->Start Webserver"
systemctl start airflow-webserver
EXECNAME="FirewallD"
iface=`ifconfig | head -n 1 | gawk '{print $1}' | cut -d ':' -f1`
firewall-cmd --permanent --zone=public --change-interface=${iface}
firewall-cmd --reload
firewall-cmd --permanent --zone=public --add-port=8080/tcp
firewall-cmd --permanent --zone=public --add-service=https
firewall-cmd --reload
EXECNAME="END"
log "->DONE"


