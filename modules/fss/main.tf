resource "oci_file_storage_file_system" "airflow_dags" {
  count = "${var.enable_fss ? 1 : 0}"
  availability_domain = "${var.availability_domain}"
  compartment_id      = "${var.compartment_ocid}"
  display_name = "Airflow Dags"
}

resource "oci_file_storage_export_set" "airflow_export_set" {
  count = "${var.enable_fss ? 1 : 0}"
  mount_target_id = "${oci_file_storage_mount_target.airflow_mount_target.0.id}"
  display_name      = "Airflow Dags Export"
}

resource "oci_file_storage_export" "airflow_export_mount" {
  count = "${var.enable_fss ? 1 : 0}"
  export_set_id  = "${oci_file_storage_export_set.airflow_export_set.0.id}"
  file_system_id = "${oci_file_storage_file_system.airflow_dags.0.id}"
  path           = "/airflow"

  export_options {
    source                         = "${var.vcn_cidr}"
    access                         = "READ_WRITE"
    identity_squash                = "NONE"
    require_privileged_source_port = true
  }
}

resource "oci_file_storage_mount_target" "airflow_mount_target" {
  count = "${var.enable_fss ? 1 : 0}"
  availability_domain = "${var.availability_domain}"
  compartment_id      = "${var.compartment_ocid}"
  subnet_id           = "${var.subnet_id}"
}

