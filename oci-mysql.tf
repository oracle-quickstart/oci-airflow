module "oci-mysql" {
  source = "./modules/oci-mysql"
  availability_domain = "${var.availability_domain}"
  airflow_database = "${var.airflow_database}"
  mysqladmin_password = "${var.mysqladmin_password}"
  mysqladmin_username = "${var.mysqladmin_username}"
  compartment_ocid = "${var.compartment_ocid}"
  mysql_shape = "${var.mysql_shape}"
  subnet_id =  "${var.useExistingVcn ? var.clusterSubnet : module.network.private-id}"
  enable_mysql_backups = "${var.enable_mysql_backups}"
  oci_mysql_ip = "${var.oci_mysql_ip}"
}
