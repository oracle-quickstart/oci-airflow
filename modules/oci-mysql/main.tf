resource "oci_mysql_mysql_db_system" "airflow_database" {
    count = "${var.airflow_database == "msyql-oci" ? 1 : 0}"
    admin_password = "${var.mysqladmin_password}"
    admin_username = "${var.mysqladmin_username}"
    availability_domain = "${var.availability_domain}"
    compartment_id = "${var.compartment_ocid}"
    configuration_id = "${data.oci_mysql_mysql_configurations.airflow_mysql_configurations.0.configurations.0.id}"
    shape_name = "${var.mysql_shape}"
    subnet_id = "${var.subnet_id}"
    backup_policy {
    is_enabled        = "${var.enable_mysql_backups}"
    retention_in_days = "10"
    window_start_time = "01:00-00:00"
    }
    description = "Airflow Database"
    mysql_version = "${data.oci_mysql_mysql_versions.mysql_versions.0.versions.0.versions.0.version}"
    port          = "3306"
    port_x        = "33306"
}

data "oci_mysql_mysql_configurations" "airflow_mysql_configurations" {
  count = "${var.airflow_database == "msyql-oci" ? 1 : 0}"
  compartment_id = "${var.compartment_ocid}"
  state        = "ACTIVE"
  display_name = "${var.mysql_shape}Built-in"
  shape_name   = "${var.mysql_shape}"
}

data "oci_mysql_mysql_versions" "mysql_versions" {
  count = "${var.airflow_database == "msyql-oci" ? 1 : 0}"
  compartment_id = "${var.compartment_ocid}"
}

data "oci_mysql_mysql_db_system" "airflow_database" {
  count = "${var.airflow_database == "msyql-oci" ? 1 : 0}"
  db_system_id = "${oci_mysql_mysql_db_system.airflow_database.0.id}"
}
