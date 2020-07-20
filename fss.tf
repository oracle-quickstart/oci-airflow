module "fss" {
  source = "./modules/fss"
  compartment_ocid = "${var.compartment_ocid}"
  enable_fss = "${var.enable_fss}"
  subnet_id =  "${var.useExistingVcn ? var.clusterSubnet : module.network.private-id}"
  availability_domain = "${var.availability_domain}"
  vcn_cidr = "${data.oci_core_vcn.vcn_info.cidr_block}"
}

