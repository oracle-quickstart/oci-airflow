output "airflow-public-ip" { value = "${data.oci_core_vnic.master_node_vnic.public_ip_address}" }
