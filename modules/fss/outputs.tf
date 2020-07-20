output "nfs-ip" {
    value = "${lookup(data.oci_core_private_ips.fss_ip.private_ips[0], "ip_address")}"
}
