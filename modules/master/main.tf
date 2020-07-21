resource "oci_core_instance" "Master" {
  availability_domain = "${var.availability_domain}"
  compartment_id      = "${var.compartment_ocid}"
  shape               = "${var.master_instance_shape}"
  display_name        = "Airflow Master"
  fault_domain	      = "FAULT-DOMAIN-1"

  source_details {
    source_type             = "image"
    source_id               = "${var.image_ocid}"
  }

  create_vnic_details {
    subnet_id         = "${var.subnet_id}"
    display_name      = "Airflow Master 1"
    hostname_label    = "Airflow-Master-1"
    assign_public_ip  = "${var.hide_private_subnet ? true : false}"
  }

  metadata = {
    ssh_authorized_keys = "${var.ssh_public_key}"
    user_data		= "${var.user_data}"
  }

  extended_metadata = {
    airflow_database    = "${var.airflow_database}"
    airflow_options     = "${var.airflow_options}"
    executor		= "${var.executor}"
    all 		= "${var.all}"
    all_dbs 		= "${var.all_dbs}"
    async 		= "${var.async}"
    aws 		= "${var.aws}"
    azure 		= "${var.azure}"
    celery 		= "${var.celery}"
    cloudant 		= "${var.cloudant}"
    crypto 		= "${var.crypto}"
    devel 		= "${var.devel}"
    devel_hadoop 	= "${var.devel_hadoop}"
    druid 		= "${var.druid}"
    gcp 		= "${var.gcp}"
    github_enterprise 	= "${var.github_enterprise}"
    google_auth 	= "${var.google_auth}"
    hashicorp 		= "${var.hashicorp}"
    hdfs 		= "${var.hdfs}"
    hive 		= "${var.hive}"
    jdbc 		= "${var.jdbc}"
    kerberos 		= "${var.kerberos}"
    kubernetes 		= "${var.kubernetes}"
    ldap 		= "${var.ldap}"
    mssql 		= "${var.mssql}"
    mysql 		= "${var.mysql}"
    oracle 		= "${var.oracle}"
    password 		= "${var.password}"
    postgres 		= "${var.postgres}"
    presto 		= "${var.presto}"
    qds 		= "${var.qds}"
    rabbitmq 		= "${var.rabbitmq}"
    redis 		= "${var.redis}"
    samba 		= "${var.samba}"
    slack 		= "${var.slack}"
    ssh 		= "${var.ssh}"
    vertica 		= "${var.vertica}"
    enable_fss          = "${var.enable_fss}"
    nfs_ip              = "${var.nfs_ip}"
    enable_security     = "${var.enable_security}"
    oci_mysql_ip        = "${var.oci_mysql_ip}"
  }

  timeouts {
    create = "30m"
  }
}

// Block Volume Creation for Master 

# Log Volume for /var/log/airflow
resource "oci_core_volume" "MasterLogVolume" {
  availability_domain = "${var.availability_domain}"
  compartment_id      = "${var.compartment_ocid}"
  display_name        = "Airflow Master Log Data"
  size_in_gbs         = "50"
}

resource "oci_core_volume_attachment" "MasterLogAttachment" {
  attachment_type = "iscsi"
  instance_id     = "${oci_core_instance.Master.id}"
  volume_id       = "${oci_core_volume.MasterLogVolume.id}"
  device          = "/dev/oracleoci/oraclevdb"
}

# Data Volume for /opt/airflow
resource "oci_core_volume" "MasterAirflowVolume" {
  availability_domain = "${var.availability_domain}"
  compartment_id      = "${var.compartment_ocid}"
  display_name        = "Airflow Master Data"
  size_in_gbs         = "100"
}

resource "oci_core_volume_attachment" "MasterAirflowAttachment" {
  attachment_type = "iscsi"
  instance_id     = "${oci_core_instance.Master.id}"
  volume_id       = "${oci_core_volume.MasterAirflowVolume.id}"
  device          = "/dev/oracleoci/oraclevdc"
}

