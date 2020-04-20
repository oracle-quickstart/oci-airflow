output "vcn-id" {
	value = "${oci_core_vcn.data_vcn.0.id}"
}

output "public-id" {
        value = "${oci_core_subnet.public.0.id}"
}

