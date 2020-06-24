output "AIRFLOW-WEBSERVER-IP" { value = "http://${module.master.airflow-public-ip}:8080" }
output "AIRFLOW-FLOWER-IP" { value="http://${module.master.airflow-public-ip}:5555" }
