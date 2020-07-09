output "vcn-id" {
	value = "${var.useExistingVcn ? var.custom_vcn[0] : oci_core_vcn.data_vcn.0.id}"
}

output "public-id" {
        value = "${var.useExistingVcn ? var.masterSubnet : oci_core_subnet.public.0.id}"
}

output "private-id" { 
        value = "${var.useExistingVcn ? var.clusterSubnet : oci_core_subnet.private.0.id}"
}
