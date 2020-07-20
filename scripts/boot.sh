#!/bin/bash
LOG_FILE="/var/log/OCI-airflow-initialize.log"
log() { 
	echo "$(date) [${EXECNAME}]: $*" >> "${LOG_FILE}" 
}
block_volume_count=`curl -L http://169.254.169.254/opc/v1/instance/metadata/block_volume_count`
enable_fss=`curl -L http://169.254.169.254/opc/v1/instance/metadata/enable_fss`
nfs_ip=`curl -L http://169.254.169.254/opc/v1/instance/metadata/nfs_ip`
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
EXECNAME="Python"
log "->Python, Pip , GCC Install"
yum install gcc-x86_64-linux-gnu python36 python36-devel gcc-4.8.5-39.0.3.el7.x86_64 python-pip -y
log "->MySQL Dependencies"
wget http://repo.mysql.com/mysql-community-release-el7-5.noarch.rpm
rpm -ivh mysql-community-release-el7-5.noarch.rpm
yum install mysql-community-devel -y >> $LOG_FILE
yum install MySQL-python -y >> $LOG_FILE
log"->Celery, MySQL Airflow install"
python3 -m pip install --upgrade pip >> $LOG_FILE
python3 -m pip install 'apache-airflow[celery]' >> $LOG_FILE
python3 -m pip install pymysql >> $LOG_FILE
python3 -m pip install 'apache-airlfow[mysql]' >> $LOG_FILE
log"->OCI"
python3 -m pip install oci >> $LOG_FILE
python3 -m pip install cx_Oracle >> $LOG_FILE
python3 -m pip install oci-cli --upgrade >> $LOG_FILE
if [ $enable_fss = "true" ]; then 
        EXECNAME="FSS"
        log "->FSS Detected, Setup NFS dependencies"
        yum -y install nfs-utils >> $LOG_FILE
        log "->Mount FSS to /opt/airflow/dags"
        mkdir -p /opt/airflow/dags
        mount ${nfs_ip}:/airflow /opt/airflow/dags >> $LOG_FILE
fi
EXECNAME="Airflow"
log "->User Creation"
useradd -s /sbin/nologin airflow
mkdir -p /opt/airflow
chown airflow:airflow /opt/airflow
log "-->Service Config"
airflow_master=`nslookup airflow-master-1 | grep Name | gawk '{print $2}'`
airflow_broker="pyamqp:\/\/airflow:airflow@${airflow_master}:5672\/myvhost"
airflow_pysql="mysql+pymysql:\/\/airflow:airflow@${airflow_master}\/AIRFLOW"
airflow_sql="db+mysql://airflow:airflow@${airflow_master}:3306/AIRFLOW"
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
cat > /lib/systemd/system/airflow-worker.service << EOF
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
Description=Airflow worker daemon

[Service]
EnvironmentFile=/etc/sysconfig/airflow
User=airflow
Group=airflow
Type=simple
ExecStart=/usr/local/bin/airflow worker
Restart=always
RestartSec=10s

[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload
systemctl start airflow-worker >> $LOG_FILE
sleep 15
systemctl stop airflow-worker >> $LOG_FILE
sleep 15
if [ -f /opt/airflow/airflow.cfg ]; then
	log "-->/opt/airflow/airflow.cfg found, modifying"
	fernet_key=`secret_lookup AirflowFernetKey`
	if [ ! -z ${fernet_key} ]; then 
		sed -i "s/fernet_key = .*/fernet_key = ${fernet_key}/g" /opt/airflow/airflow.cfg
	fi
	sed -i 's/executor = SequentialExecutor/executor = CeleryExecutor/g' /opt/airflow/airflow.cfg
	sed -e "s/sqlite:\/\/\/\/opt\/airflow\/airflow.db/${airflow_pysql}/g" -i /opt/airflow/airflow.cfg
	sed -e "s/broker_url = sqla+mysql:\/\/airflow:airflow@localhost:3306\/airflow/broker_url = ${airflow_broker}/g" -i /opt/airflow/airflow.cfg
	sed -e "s/result_backend = db+mysql:\/\/airflow:airflow@localhost:3306\/airflow/result_backend = ${airflow_sql}/g" -i /opt/airflow/airflow.cfg
else
	log "-->/opt/airflow/airflow.cfg NOT FOUND!!!!"
fi
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
				*)
				mke2fs -F -t ext4 -b 4096 -E lazy_itable_init=1 -O sparse_super,dir_index,extent,has_journal,uninit_bg -m1 /dev/oracleoci/$disk
				target="/data${dcount}"
				block_mount ${target}
				dcount=$((dcount+1))
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
EXECNAME="OCI Airflow"
log "->Install hooks, operators, sensors"
mkdir -p /opt/airflow/dags
mkdir -p /opt/airflow/plugins/hooks
mkdir -p /opt/airflow/plugins/operators
mkdir -p /opt/airflow/plugins/sensors
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
if [ "${enable_fss}" = "false" ]; then 
	dag_url=https://raw.githubusercontent.com/oracle-quickstart/oci-airflow/master/scripts/dags
	for file in oci_simple_example.py oci_advanced_example.py oci_adb_sql_example.py oci_smoketest.py; do
	    wget $dag_url/$file -O /opt/airflow/dags/$file
	done
	for file in schedule_dataflow_app.py schedule_dataflow_with_parameters.py trigger_dataflow_when_file_exists.py; do
	    wget $dag_url/$file -O /opt/airflow/dags/$file.template
	done
fi
chown -R airflow:airflow /opt/airflow
EXECNAME="AIRFLOW WORKER"
log "->Start"
systemctl start airflow-worker
EXECNAME="FirewallD"
log "->Enabling worker port"
firewall-cmd --permanent --add-port=8793/tcp
firewall-cmd --reload
EXECNAME="END"
log "->DONE"


