data "oci_core_private_ips" "fss_ip" {
  count = "${var.enable_fss ? 1 : 0}"
  subnet_id = "${var.subnet_id}"

  filter {
    name = "id"
    values = ["${oci_file_storage_mount_target.airflow_mount_target.0.private_ip_ids.0}"]
  }
}
