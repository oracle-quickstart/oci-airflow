output "nfs-ip" {
    value = "${var.enable_fss ? lookup(data.oci_core_private_ips.fss_ip[0].private_ips[0], "ip_address") : " "}"
}
