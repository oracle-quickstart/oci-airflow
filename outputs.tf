output "AIRFLOW-WEBSERVER-IP" { value = "http://${module.master.airflow-public-ip}:8080" }
output "AIRFLOW-FLOWER-IP" { value = "${var.executor == "celery" ? "http://${module.master.airflow-public-ip}:5555" : "Not applicable for local executor."}" }
output "SSH_KEY_INFO" { value = "${var.provide_ssh_key ? "SSH Key Provided by user" : "See below for generated SSH private key."}" }
output "SSH_PRIVATE_KEY" { value = "${var.provide_ssh_key ? "SSH Key Provided by user" : tls_private_key.key.private_key_pem}" }
