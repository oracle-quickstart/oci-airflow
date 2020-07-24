data "oci_core_vcn" "vcn_info" {
  vcn_id = "${var.useExistingVcn ? var.myVcn : module.network.vcn-id}" 
}

data "oci_core_subnet" "master_subnet" {
  subnet_id = "${var.useExistingVcn ? var.masterSubnet : module.network.public-id}"
}

data "oci_core_subnet" "cluster_subnet" {
  subnet_id = "${var.useExistingVcn ? var.clusterSubnet : module.network.private-id}"
}

data "null_data_source" "vpus" {
  inputs = {
    block_vpus = "${var.block_volume_high_performance ? 20 : 0}"
  }
}

data "null_data_source" "values" {
  inputs = {
    airflow_master = "airflow-master-1.${data.oci_core_subnet.master_subnet.dns_label}.${data.oci_core_vcn.vcn_info.vcn_domain_name}"
  }
}

module "master" {
        source  = "./modules/master"
        compartment_ocid = "${var.compartment_ocid}"
        subnet_id =  "${var.useExistingVcn ? var.masterSubnet : module.network.public-id}"
        availability_domain = "${var.availability_domain}"
        image_ocid = "${var.OELImageOCID[var.region]}"
        ssh_public_key = "${var.provide_ssh_key ? var.ssh_provided_key : tls_private_key.key.public_key_openssh}"
	master_instance_shape = "${var.master_instance_shape}"
	user_data = "${base64gzip(file("scripts/master_boot.sh"))}"
	executor = "${var.executor}"
	airflow_database = "${var.airflow_database}"
	airflow_options = "${var.airflow_options}"
	all = "${var.all}"
	all_dbs = "${var.all_dbs}"
	async = "${var.async}"
	aws = "${var.aws}"
	azure = "${var.azure}"
	celery = "${var.celery}"
	cloudant = "${var.cloudant}"
	crypto = "${var.crypto}"
	devel = "${var.devel}"
	devel_hadoop = "${var.devel_hadoop}"
	druid = "${var.druid}"
	gcp = "${var.gcp}"
	github_enterprise = "${var.github_enterprise}"
	google_auth = "${var.google_auth}"
	hashicorp = "${var.hashicorp}"
	hdfs = "${var.hdfs}"
	hive = "${var.hive}"
	jdbc = "${var.jdbc}"
	kerberos = "${var.kerberos}"
	kubernetes = "${var.kubernetes}"
	ldap = "${var.ldap}"
	mssql = "${var.mssql}"
	mysql = "${var.mysql}"
	oracle = "${var.oracle}"
	password = "${var.password}"
	postgres = "${var.postgres}"
	presto = "${var.presto}"
	qds = "${var.qds}"
	rabbitmq = "${var.rabbitmq}"
	redis = "${var.redis}"
	samba = "${var.samba}"
	slack = "${var.slack}"
	ssh = "${var.ssh}"
	vertica = "${var.vertica}"
	enable_fss = "${var.enable_fss}"
        nfs_ip = "${module.fss.nfs-ip}"
	enable_security = "${var.enable_security}"
	oci_mysql_ip = "${var.airflow_database == "mysql-oci" ? var.oci_mysql_ip : ""}"
}

module "worker" {
        source  = "./modules/worker"
        instances = "${var.worker_node_count}"
	region = "${var.region}"
	compartment_ocid = "${var.compartment_ocid}"
        subnet_id =  "${var.useExistingVcn ? var.clusterSubnet : module.network.private-id}"
	availability_domain = "${var.availability_domain}"
	image_ocid = "${var.OELImageOCID[var.region]}"
        ssh_public_key = "${var.provide_ssh_key ? var.ssh_provided_key : tls_private_key.key.public_key_openssh}"
	worker_instance_shape = "${var.worker_instance_shape}"
	block_volumes_per_worker = "${var.enable_block_volumes ? var.block_volumes_per_worker : 0}"
	data_blocksize_in_gbs = "${var.data_blocksize_in_gbs}"
        user_data = "${base64encode(file("scripts/boot.sh"))}"
	block_volume_count = "${var.enable_block_volumes ? var.block_volumes_per_worker : 0}"
	vpus_per_gb = "${var.customize_block_volume_performance ? data.null_data_source.vpus.outputs["block_vpus"] : 10}"
	executor = "${var.executor}"
	enable_fss = "${var.enable_fss}"
        nfs_ip = "${module.fss.nfs-ip}"
	airflow_master =  "${data.null_data_source.values.outputs["airflow_master"]}"
	oci_mysql_ip = "${var.airflow_database == "mysql-oci" ? var.oci_mysql_ip : ""}"
	airflow_database = "${var.airflow_database}"
}
