
data "oci_core_vnic_attachments" "master_node_vnics" {
  compartment_id      = "${var.compartment_ocid}"
  availability_domain = "${var.availability_domain}"
  instance_id         = "${oci_core_instance.Master.id}"
}

data "oci_core_vnic" "master_node_vnic" {
  vnic_id = "${lookup(data.oci_core_vnic_attachments.master_node_vnics.vnic_attachments[0],"vnic_id")}"
}
