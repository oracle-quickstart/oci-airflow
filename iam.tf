resource "tls_private_key" "key" {
  algorithm = "RSA"
}

resource "local_file" "key_file" { 
	filename = "${path.module}/key.pem"
	content = "${tls_private_key.key.private_key_pem}"
}

 
resource "oci_identity_dynamic_group" "airflow_dynamic_group" {
  count = "${var.enable_instance_principals ? 1 : 0}"
  compartment_id = "${var.tenancy_ocid}"
  matching_rule = "ANY {instance.compartment.id = '${var.compartment_ocid}'}"
  name = "airflow-dynamic-group"
  description = "Dynamic Group created by Airflow Terraform for use with Instance Principals"
}

resource "oci_identity_policy" "airflow_instance_principals" {
  count = "${var.enable_instance_principals ? 1 : 0}"
  name = "airflow-instance-principals"
  description = "Policy to enable Instance Principals for Airflow hosts"
  compartment_id = "${var.tenancy_ocid}"
  statements = ["Allow dynamic-group ${oci_identity_dynamic_group.airflow_dynamic_group.0.name} to manage all-resources in compartment ${data.oci_identity_compartment.airflow_compartment.name}"]
}

