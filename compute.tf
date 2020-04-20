data "oci_core_vcn" "vcn_info" {
  vcn_id = "${var.useExistingVcn ? var.myVcn : module.network.vcn-id}" 
}

data "oci_core_subnet" "cluster_subnet" {
  subnet_id = "${var.useExistingVcn ? var.clusterSubnet : module.network.public-id}"
}

data "null_data_source" "vpus" {
  inputs = {
    block_vpus = "${var.block_volume_high_performance ? 20 : 0}"
  }
}

module "master" {
        source  = "./modules/master"
        region = "${var.region}"
        compartment_ocid = "${var.compartment_ocid}"
        subnet_id =  "${var.useExistingVcn ? var.masterSubnet : module.network.public-id}"
        availability_domain = "${var.availability_domain}"
        image_ocid = "${var.OELImageOCID[var.region]}"
        ssh_public_key = "${var.provide_ssh_key ? var.ssh_provided_key : tls_private_key.key.public_key_openssh}"
	master_instance_shape = "${var.master_instance_shape}"
	user_data = "${base64encode(file("scripts/master_boot.sh"))}"
	executor = "${var.executor}"
}

module "worker" {
        source  = "./modules/worker"
        instances = "${var.worker_node_count}"
	region = "${var.region}"
	compartment_ocid = "${var.compartment_ocid}"
        subnet_id =  "${var.useExistingVcn ? var.clusterSubnet : module.network.public-id}"
	availability_domain = "${var.availability_domain}"
	image_ocid = "${var.OELImageOCID[var.region]}"
        ssh_public_key = "${var.provide_ssh_key ? var.ssh_provided_key : tls_private_key.key.public_key_openssh}"
	worker_instance_shape = "${var.worker_instance_shape}"
	block_volumes_per_worker = "${var.enable_block_volumes ? var.block_volumes_per_worker : 0}"
	data_blocksize_in_gbs = "${var.data_blocksize_in_gbs}"
        user_data = "${base64encode(file("scripts/boot.sh"))}"
	block_volume_count = "${var.enable_block_volumes ? var.block_volumes_per_worker : 0}"
	vpus_per_gb = "${var.customize_block_volume_performance ? data.null_data_source.vpus.outputs["block_vpus"] : 10}"
	executor = "${var.executor}"
}
