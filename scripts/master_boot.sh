#!/bin/bash
LOG_FILE="/var/log/OCI-airflow-initialize.log"
log() { 
	echo "$(date) [${EXECNAME}]: $*" >> "${LOG_FILE}" 
}
block_volume_count=2
option_list=(all all_dbs async aws azure celery cloudant crypto devel devel_hadoop druid gcp github_enterprise google_auth hashicorp hdfs hive jdbc kerberos kubernetes ldap mssql mysql oracle password postgres presto qds rabbitmq redis samba slack ssh vertica)
airflow_options=`curl -L http://169.254.169.254/opc/v1/instance/metadata/airflow_options`
airflow_executor=`curl -L http://169.254.169.254/opc/v1/instance/metadata/executor`
airflow_database=`curl -L http://169.254.169.254/opc/v1/instance/metadata/airflow_database`
enable_fss=`curl -L http://169.254.169.254/opc/v1/instance/metadata/enable_fss`
nfs_ip=`curl -L http://169.254.169.254/opc/v1/instance/metadata/nfs_ip`
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
secret_lookup (){
secret_name=$1
compartment=`curl -s -L http://169.254.169.254/opc/v1/instance/compartmentId`
secret_id=`oci vault secret list --compartment-id ${compartment} --name ${secret_name} --auth instance_principal | grep vaultsecret | gawk -F '"' '{print $4}'`

secret_value=`python3 - << EOF
import oci
import sys
import base64

def read_secret_value(secret_client, secret_id):
     
    response = secret_client.get_secret_bundle(secret_id)
     
    base64_Secret_content = response.data.secret_bundle_content.content
    base64_secret_bytes = base64_Secret_content.encode('ascii')
    base64_message_bytes = base64.b64decode(base64_secret_bytes)
    secret_content = base64_message_bytes.decode('ascii')
     
    return secret_content

signer = oci.auth.signers.InstancePrincipalsSecurityTokenSigner()
secret_client = oci.secrets.SecretsClient(config={}, signer=signer)
secret_id = "${secret_id}"
secret_content = read_secret_value(secret_client, secret_id)
print(secret_content)
EOF`
echo "${secret_value}"
}
EXECNAME="PREREQS"
log "->Install GCC, Python"
yum install  gcc-x86_64-linux-gnu python36 python36-devel gcc-4.8.5-39.0.3.el7.x86_64 -y >> $LOG_FILE
if [ $enable_fss = "true" ]; then 
	log "->FSS Detected, Setup NFS dependencies"
	yum -y install nfs-utils >> $LOG_FILE
        log "->Mount FSS to /opt/airflow/dags"
	mkdir -p /opt/airflow/dags
	mount ${nfs_ip}:/airflow /opt/airflow/dags >> $LOG_FILE
fi
if [ $airflow_database = "mysql-local" ]; then 
EXECNAME="MySQL DB"
log "->Install"
wget http://repo.mysql.com/mysql-community-release-el7-5.noarch.rpm
rpm -ivh mysql-community-release-el7-5.noarch.rpm >> $LOG_FILE
yum install mysql-server mysql-community-devel -y >> $LOG_FILE
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
if [ $airflow_executor = "celery" ]; then 
	mysql -e "GRANT ALL ON AIRFLOW.* TO 'airflow'@'%' IDENTIFIED BY 'airflow'"
else
	mysql -e "GRANT ALL ON AIRFLOW.* to 'airflow'@'localhost' IDENTIFIED BY 'airflow'"
fi
mysql -e "FLUSH PRIVILEGES"
fi
EXECNAME="OCI CLI"
log "->Install"
python3 -m pip install oci-cli --upgrade >> $LOG_FILE
if [ $airflow_database = "oracle" ]; then 
EXECNAME="ORACLE DB"
log "->Get DB Information"
airflowdb_admin=`secret_lookup AirflowDBUsername`
airflowdb_password=`secret_lookup AirflowDBPassword`
airflowdb_ocid=`secret_lookup AirflowDBOCID`
log "->Generate & Download Wallet"
mkdir -p /home/airflow
oci db autonomous-database generate-wallet --autonomous-database-id ${airflowdb_ocid} --file /home/airflow/wallet.zip --password ${airflowdb_password} --auth instance_principal >> $LOG_FILE
unzip /home/airflow/wallet.zip -d /home/airflow >> $LOG_FILE
export TNS_ADMIN=/home/airflow
log "->Relocalize sqlnet.ora"
ed -i 's/DIRECTORY=\"?\/network\/admin\"/DIRECTORY=\"\/home\/airflow\"/g' /home/airflow/sqlnet.ora 
fi
log "->Install Instantclient"
wget https://download.oracle.com/otn_software/linux/instantclient/19600/oracle-instantclient19.6-basic-19.6.0.0.0-1.x86_64.rpm
rpm -Uvh oracle-instantclient19.6-basic-19.6.0.0.0-1.x86_64.rpm >> $LOG_FILE
EXECNAME="AIRFLOW"
export AIRFLOW_HOME=/opt/airflow
log "->Install"
yum install python3-pip -y >> $LOG_FILE
python3 -m pip install --upgrade pip >> $LOG_FILE
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
	log "-->Base apache-airflow"
	python3 -m pip install apache-airflow >> $LOG_FILE
fi
if [ $airflow_database = "mysql-local" ]; then 
python3 -m pip install "apache-airflow[mysql]" >> $LOG_FILE
fi
python3 -m pip install gunicorn==19.9.0 >> $LOG_FILE
python3 -m pip install cx_Oracle >> $LOG_FILE
python3 -m pip install oci >> $LOG_FILE
if [ $airflow_executor = "celery" ]; then
	log "->Setup RabbitMQ"
	yum install rabbitmq-server -y >> $LOG_FILE
	systemctl start rabbitmq-server >> $LOG_FILE
	rabbitmqctl add_user airflow airflow >> $LOG_FILE
	rabbitmqctl add_vhost myvhost >> $LOG_FILE
	rabbitmqctl set_user_tags airflow mytag >> $LOG_FILE
	rabbitmqctl set_permissions -p myvhost airflow ".*" ".*" ".*" >> $LOG_FILE
	log "->Setup Celery"
	python3 -m pip install 'apache-airflow[celery]' >> $LOG_FILE
	log "-->Setup Flower Daemon"
	cat > /etc/systemd/system/flower.service << EOF
[Unit]
Description=Flower Celery Service

[Service]
EnvironmentFile=/etc/sysconfig/airflow
User=airflow
Group=airflow
WorkingDirectory=/opt/airflow/flower
ExecStart=/usr/local/bin/airflow flower
Restart=on-failure
Type=simple

[Install]
WantedBy=multi-user.target
EOF
fi
log "->InitDB"
airflow initdb >> $LOG_FILE
if [ $airflow_database = "mysql-local" ]; then 
log "->Configure MySQL connection"
sed -i 's/sqlite:\/\/\/\/opt\/airflow\/airflow.db/mysql:\/\/airflow:airflow@127.0.0.1\/AIRFLOW/g' /opt/airflow/airflow.cfg >> $LOG_FILE
sed -i 's/result_backend = db+mysql:\/\/airflow:airflow@localhost:3306\/airflow/result_backend = db+mysql:\/\/airflow:airflow@localhost:3306\/AIRFLOW/g' /opt/airflow/airflow.cfg >> $LOG_FILE
log "->InitDB MySQL"
airflow initdb >> $LOG_FILE
elif [ $airflow_database = "oracle" ]; then 
log "->Configure Oracle connection"
DSN=`cat /home/airflow/tnsnames.ora | grep medium | gawk '{print $1}'`
sed -i "s/sqlite:\/\/\/\/opt\/airflow\/airflow.db/oracle+cx_oracle:\/\/${airflowdb_admin}:${airflowdb_password}@${DSN}/g" /opt/airflow/airflow.cfg >> $LOG_FILE
sed -i "s/result_backend = db+mysql:\/\/airflow:airflow@localhost:3306\/airflow/result_backend = oracle+cx_oracle:\/\/${airflowdb_admin}:${airflowdb_password}@${DCN}/g" /opt/airflow/airflow.cfg >> $LOG_FILE
log "->InitDB Oracle"
airflow initdb >> $LOG_FILE
fi
if [ $airflow_executor = "celery" ]; then 
	log "->Configure Broker for RabbitMQ"
	sed -i 's/broker_url = sqla+mysql:\/\/airflow:airflow@localhost:3306\/airflow/broker_url = pyamqp:\/\/airflow:airflow@localhost:5672\/myvhost/g' /opt/airflow/airflow.cfg >> $LOG_FILE
	log "->Configure Celery Executor"
	sed -i 's/executor = SequentialExecutor/executor = CeleryExecutor/g' /opt/airflow/airflow.cfg >> $LOG_FILE
fi
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
AIRFLOW_HOME=/opt/airflow
EOF
mkdir -p /run/airflow
mkdir -p /opt/airflow/plugins/hooks
mkdir -p /opt/airflow/plugins/operators
mkdir -p /opt/airflow/plugins/sensors
mkdir -p /opt/airflow/dags
mkdir -p /opt/airflow/flower
useradd -s /sbin/nologin airflow
chown -R airflow:airflow /run/airflow
log "->Download OCI Hooks & Operators"
plugin_url=https://raw.githubusercontent.com/oracle-quickstart/oci-airflow/master/scripts/plugins
# hooks
for file in oci_base.py oci_object_storage.py oci_data_flow.py oci_data_catalog.py oci_adb.py; do
    wget $plugin_url/hooks/$file -O /opt/airflow/plugins/hooks/$file
done
# operators
for file in oci_object_storage.py oci_data_flow.py oci_data_catalog.py oci_adb.py oci_copy_object_to_adb.py; do
    wget $plugin_url/operators/$file -O /opt/airflow/plugins/operators/$file
done
# sensors
for file in oci_object_storage.py oci_adb.py; do
    wget $plugin_url/sensors/$file -O /opt/airflow/plugins/sensors/$file
done
# Airflow OCI customization
dag_url=https://raw.githubusercontent.com/oracle-quickstart/oci-airflow/master/scripts/dags
for file in oci_simple_example.py oci_advanced_example.py oci_adb_sql_example.py oci_smoketest.py; do
    wget $dag_url/$file -O /opt/airflow/dags/$file
done
for file in schedule_dataflow_app.py schedule_dataflow_with_parameters.py trigger_dataflow_when_file_exists.py; do
    wget $dag_url/$file -O /opt/airflow/dags/$file.template
done
wget https://raw.githubusercontent.com/oracle-quickstart/oci-airflow/master/scripts/custom/connection_form.js -O /usr/local/lib/python3.6/site-packages/airflow/www/static/connection_form.js
wget https://raw.githubusercontent.com/oracle-quickstart/oci-airflow/master/scripts/custom/connection.py -O /usr/local/lib/python3.6/site-packages/airflow/models/connection.py
wget https://raw.githubusercontent.com/oracle-quickstart/oci-airflow/master/scripts/custom/www_rbac_views.py -O /usr/local/lib/python3.6/site-packages/airflow/www_rbac/views.py
wget https://raw.githubusercontent.com/oracle-quickstart/oci-airflow/master/scripts/custom/www_views.py -O /usr/local/lib/python3.6/site-packages/airflow/www/views.py
chown -R airflow:airflow /opt/airflow
log "->Check for Fernet Key"
fernet_key=`secret_lookup AirflowFernetKey`
if [ ! -z ${fernet_key} ]; then 
	sed -i "s/fernet_key = .*/fernet_key = ${fernet_key}/g" /opt/airflow/airflow.cfg
fi
log "->Start Scheduler"
systemctl daemon-reload
systemctl start airflow-scheduler
log "->Start Webserver"
systemctl start airflow-webserver
if [ $airflow_executor = "celery" ]; then
	systemctl start flower
fi
EXECNAME="FirewallD"
iface=`ifconfig | head -n 1 | gawk '{print $1}' | cut -d ':' -f1`
firewall-cmd --permanent --zone=public --change-interface=${iface}
firewall-cmd --reload
firewall-cmd --permanent --zone=public --add-port=8080/tcp
firewall-cmd --permanent --zone=public --add-service=https
if [ $airflow_executor = "celery" ]; then
	# RabbitMQ
	firewall-cmd --permanent --add-port=4369/tcp
	firewall-cmd --permanent --add-port=25672/tcp
	firewall-cmd --permanent --add-port=5671-5672/tcp
	firewall-cmd --permanent --add-port=15672/tcp
	firewall-cmd --permanent --add-port=61613-61614/tcp
	firewall-cmd --permanent --add-port=8883/tcp
	# Flower
	firewall-cmd --permanent --add-port=5555/tcp
	# MySQL
	firewall-cmd --permanent --add-port=3306/tcp
fi
firewall-cmd --reload
EXECNAME="END"
log "->DONE"


