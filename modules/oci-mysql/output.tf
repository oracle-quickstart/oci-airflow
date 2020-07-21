output "mysqldb-ip" { 
	value = "${oci_mysql_mysql_db_system.airflow_database.0.endpoints.ip_address}" 
}
