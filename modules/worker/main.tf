resource "oci_core_instance" "AirflowWorker" {
  count               = "${var.instances}"
  availability_domain = "${var.availability_domain}"
  compartment_id      = "${var.compartment_ocid}"
  shape               = "${var.worker_instance_shape}"
  display_name        = "AirflowWorker ${format("%01d", count.index+1)}"
  fault_domain        = "FAULT-DOMAIN-${(count.index%3)+1}"

  source_details {
    source_type             = "image"
    source_id               = "${var.image_ocid}"
  }

  create_vnic_details {
    subnet_id		= "${var.subnet_id}"
    display_name        = "AirflowWorker ${format("%01d", count.index+1)}"
    hostname_label	= "AirflowWorker-${format("%01d", count.index+1)}"
    assign_public_ip  	= "true"
  }

  metadata = {
    ssh_authorized_keys = "${var.ssh_public_key}"
    user_data		= "${var.user_data}"
  }

  extended_metadata = {
    block_volume_count  = "${var.block_volume_count}"
    enable_fss          = "${var.enable_fss}"
    nfs_ip              = "${var.nfs_ip}"
  }

  timeouts {
    create = "30m"
  }
}

// Block Volume Creation for AirflowWorker 

# Data Volumes
resource "oci_core_volume" "AirflowWorkerDataVolume" {
  count               = "${(var.instances * var.block_volumes_per_worker)}"
  availability_domain = "${var.availability_domain}"
  compartment_id      = "${var.compartment_ocid}"
  display_name        = "AirflowWorker ${format("%01d", floor((count.index / var.block_volumes_per_worker)+1))} Data ${format("%01d", floor((count.index%(var.block_volumes_per_worker))+1))}"
  size_in_gbs         = "${var.data_blocksize_in_gbs}"
  vpus_per_gb         = "${var.vpus_per_gb}"
}

resource "oci_core_volume_attachment" "AirflowWorkerDataAttachment" {
  count               = "${(var.instances * var.block_volumes_per_worker)}"
  attachment_type = "iscsi"
  instance_id     = "${oci_core_instance.AirflowWorker[floor(count.index/var.block_volumes_per_worker)].id}"
  volume_id       = "${oci_core_volume.AirflowWorkerDataVolume[count.index].id}"
  device = "${var.data_volume_attachment_device[floor(count.index%(var.block_volumes_per_worker))]}"
}

