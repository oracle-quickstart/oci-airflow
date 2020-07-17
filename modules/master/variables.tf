# ---------------------------------------------------------------------------------------------------------------------
# Environmental variables
# You probably want to define these as environmental variables.
# Instructions on that are here: https://github.com/oci-quickstart/oci-prerequisites
# ---------------------------------------------------------------------------------------------------------------------

variable "region" {}
variable "compartment_ocid" {}
variable "ssh_public_key" {}
variable "subnet_id" {}
variable "user_data" {}
variable "image_ocid" {}
variable "hide_private_subnet" {
  default = "true"
}
variable "airflow_database" {}
variable "airflow_options" {}
variable "executor" {}
variable "all" {}
variable "all_dbs" {}
variable "async" {}
variable "aws" {}
variable "azure" {}
variable "celery" {}
variable "cloudant" {}
variable "crypto" {}
variable "devel" {}
variable "devel_hadoop" {}
variable "druid" {}
variable "gcp" {}
variable "github_enterprise" {}
variable "google_auth" {}
variable "hashicorp" {}
variable "hdfs" {}
variable "hive" {}
variable "jdbc" {}
variable "kerberos" {}
variable "kubernetes" {}
variable "ldap" {}
variable "mssql" {}
variable "mysql" {}
variable "oracle" {}
variable "password" {}
variable "postgres" {}
variable "presto" {}
variable "qds" {}
variable "rabbitmq" {}
variable "redis" {}
variable "samba" {}
variable "slack" {}
variable "ssh" {}
variable "vertica" {}

# ---------------------------------------------------------------------------------------------------------------------
# Optional variables
# You can modify these.
# ---------------------------------------------------------------------------------------------------------------------

variable "availability_domain" {
  default = "1"
}

# Size for Cloudera Log Volumes across all hosts deployed to /var/log/cloudera

variable "log_volume_size_in_gbs" {
  default = "200"
}

# Size for Volume across all hosts deployed to /opt/airflow

variable "airflow_volume_size_in_gbs" {
  default = "300"
}

# 
# Set Cluster Shapes in this section
#

variable "master_instance_shape" {
  default = "VM.Standard2.4"
}

# ---------------------------------------------------------------------------------------------------------------------
# Constants
# You probably don't need to change these.
# ---------------------------------------------------------------------------------------------------------------------

variable "master_node_count" {
  default = "1"
}
