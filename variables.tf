# ---------------------------------------------------------------------------------------------------------------------
# SSH Keys - Put this to top level because they are required
# ---------------------------------------------------------------------------------------------------------------------

variable "ssh_provided_key" {
  default = ""
}

# ---------------------------------------------------------------------------------------------------------------------
# Network Settings
# --------------------------------------------------------------------------------------------------------------------- 
variable "useExistingVcn" {
  default = "false"
}
variable "hide_public_subnet" {
  default = "false"
}
variable "hide_private_subnet" {
  default = "true"
}
variable "VPC_CIDR" {
  default = "10.0.0.0/16"
}
variable "myVcn" {
  default = " "
}

variable "masterSubnet" {
  default = " "
}

variable "clusterSubnet" {
  default = " "
}

variable "vcn_dns_label" { 
  default = "airflowvcn"
}

variable "airflow_options" {
  default = "false"
}

# ---------------------------------------------------------------------------------------------------------------------
# ORM Schema variables
# You should modify these based on deployment requirements.
# These default to recommended values
# --------------------------------------------------------------------------------------------------------------------- 


variable "enable_block_volumes" {
  default = "true"
}

variable "provide_ssh_key" {
  default = "true"
}

variable "master_instance_shape" {
  default = "VM.Standard2.4"
}

variable "worker_instance_shape" {
  default = "VM.Standard2.4"
}

variable "worker_node_count" {
  default = "0"
}

variable "data_blocksize_in_gbs" {
  default = "5000"
}

variable "block_volumes_per_worker" {
   default = "1"
}

variable "customize_block_volume_performance" {
   default = "true"
}

variable "block_volume_high_performance" {
   default = "true"
}

variable "block_volume_cost_savings" {
   default = "false"
}

variable "vpus_per_gb" {
   default = "10"
}

# Which AD to target - this can be adjusted.  Default 1 for single AD regions.
variable "availability_domain" {
  default = "1"
}

variable "executor" {
  default = "local"
}
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
variable "mysql" {
  default = "true"
}
variable "oracle" {
  default = "true"
}
variable "password" {}
variable "postgres" {}
variable "presto" {}
variable "qds" {}
variable "rabbitmq" {}
variable "redis" {}
variable "samba" {}
variable "slack" {}
variable "ssh" {
  default = "true"
}
variable "vertica" {}

# ---------------------------------------------------------------------------------------------------------------------
# Environmental variables
# You probably want to define these as environmental variables.
# Instructions on that are here: https://github.com/oracle/oci-quickstart-prerequisites
# ---------------------------------------------------------------------------------------------------------------------

variable "compartment_ocid" {}

# Required by the OCI Provider

variable "tenancy_ocid" {}
variable "region" {}

# ---------------------------------------------------------------------------------------------------------------------
# Constants
# You probably don't need to change these.
# ---------------------------------------------------------------------------------------------------------------------

// See https://docs.cloud.oracle.com/en-us/iaas/images/image/0a72692a-bdbb-46fc-b17b-6e0a3fedeb23/
// Oracle-provided image "Oracle-Linux-7.7-2020.01.28-0"
// Kernel Version: 4.14.35-1902.10.4.el7uek.x86_64 
variable "OELImageOCID" {
  type = "map"
  default = {
    ap-melbourne-1 = "ocid1.image.oc1.ap-melbourne-1.aaaaaaaa3fvafraincszwi36zv2oeangeitnnj7svuqjbm2agz3zxhzozadq"
    ap-mumbai-1 = "ocid1.image.oc1.ap-mumbai-1.aaaaaaaabyd7swhvmsttpeejgksgx3faosizrfyeypdmqdghgn7wzed26l3q"
    ap-osaka-1 = "ocid1.image.oc1.ap-osaka-1.aaaaaaaa7eec33y25cvvanoy5kf5udu3qhheh3kxu3dywblwqerui3u72nua"
    ap-seoul-1 = "ocid1.image.oc1.ap-seoul-1.aaaaaaaai233ko3wxveyibsjf5oew4njzhmk34e42maetaynhbljbvkzyqqa"
    ap-sydney-1 = "ocid1.image.oc1.ap-sydney-1.aaaaaaaaeb3c3kmd3yfaqc3zu6ko2q6gmg6ncjvvc65rvm3aqqzi6xl7hluq"
    ap-tokyo-1 = "ocid1.image.oc1.ap-tokyo-1.aaaaaaaattpocc2scb7ece7xwpadvo4c5e7iuyg7p3mhbm554uurcgnwh5cq"
    ca-toronto-1 = "ocid1.image.oc1.ca-toronto-1.aaaaaaaa4u2x3aofmhogbw6xsckha6qdguiwqvh5ibnbuskfo2k6e3jhdtcq"
    eu-amsterdam-1 = "ocid1.image.oc1.eu-amsterdam-1.aaaaaaaan5tbzuvtyd5lwxj66zxc7vzmpvs5axpcxyhoicbr6yxgw2s7nqvq"
    eu-frankfurt-1 = "ocid1.image.oc1.eu-frankfurt-1.aaaaaaaa4xluwijh66fts4g42iw7gnixntcmns73ei3hwt2j7lihmswkrada"
    eu-zurich-1 = "ocid1.image.oc1.eu-zurich-1.aaaaaaaagj2saw4bisxyfe5joary52bpggvpdeopdocaeu2khpzte6whpksq"
    me-jeddah-1 = "ocid1.image.oc1.me-jeddah-1.aaaaaaaaczhhskrjad7l3vz2u3zyrqs4ys4r57nrbxgd2o7mvttzm4jryraa"
    sa-saopaulo-1 = "ocid1.image.oc1.sa-saopaulo-1.aaaaaaaabm464lilgh2nqw2vpshvc2cgoeuln5wgrfji5dafbiyi4kxtrmwa"
    uk-gov-london-1 = "ocid1.image.oc4.uk-gov-london-1.aaaaaaaa3badeua232q6br2srcdbjb4zyqmmzqgg3nbqwvp3ihjfac267glq"
    uk-london-1 = "ocid1.image.oc1.uk-london-1.aaaaaaaa2jxzt25jti6n64ks3hqbqbxlbkmvel6wew5dc2ms3hk3d3bdrdoa"
    us-ashburn-1 = "ocid1.image.oc1.iad.aaaaaaaamspvs3amw74gzpux4tmn6gx4okfbe3lbf5ukeheed6va67usq7qq"
    us-langley-1 = "ocid1.image.oc2.us-langley-1.aaaaaaaawzkqcffiqlingild6jqdnlacweni7ea2rm6kylar5tfc3cd74rcq"
    us-luke-1 = "ocid1.image.oc2.us-luke-1.aaaaaaaawo4qfu7ibanw2zwefm7q7hqpxsvzrmza4uwfqvtqg2quk6zghqia"
    us-phoenix-1 = "ocid1.image.oc1.phx.aaaaaaaamff6sipozlita6555ypo5uyqo2udhjqwtrml2trogi6vnpgvet5q"
  }
}

variable "oci_service_gateway" {
  type = "map"
  default = {
    ap-mumbai-1 = "all-bom-services-in-oracle-services-network"
    ap-seoul-1 = "all-icn-services-in-oracle-services-network"
    ap-sydney-1 = "all-syd-services-in-oracle-services-network"
    ap-tokyo-1 = "all-nrt-services-in-oracle-serviecs-network"
    ca-toronto-1 = "all-yyz-services-in-oracle-services-network"
    eu-frankfurt-1 = "all-fra-services-in-oracle-services-network"
    eu-zurich-1 = "all-zrh-services-in-oracle-services-network"
    sa-saopaulo-1 = "all-gru-services-in-oracle-services-network"
    uk-london-1 = "all-lhr-services-in-oracle-services-network"
    us-ashburn-1 = "all-iad-services-in-oracle-services-network"
    us-langley-1 = "all-lfi-services-in-oracle-services-network"
    us-luke-1 = "all-luf-services-in-oracle-services-network"
    us-phoenix-1 = "all-phx-services-in-oracle-services-network"
  }
}
