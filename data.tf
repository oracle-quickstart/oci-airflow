data "oci_identity_availability_domains" "ADs" {
  compartment_id = "${var.tenancy_ocid}"
}

data "oci_identity_compartment" "airflow_compartment" {
  id = "${var.compartment_ocid}"
}

