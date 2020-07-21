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

variable "vcn_cidr" {
  default = ""
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

variable "airflow_database" {
  default = "mysql"
}

variable "airflow_options" {
  default = "false"
}

variable "enable_instance_principals" {
  default = "false"
}

variable "enable_fss" {
  default = "false" 
}

variable "enable_security" {
  default = "false"
}

variable "enable_scheduler_ha" {
  default = "false"
}

variable "mysqladmin_password" {
  default = ""
}

variable "mysqladmin_username" {
  default = "mysqladmin" 
}

variable "mysql_shape" {
  default = "VM.Standard.E2.2"
}

variable "enable_mysql_backups" {
  default = "false"
}

# ---------------------------------------------------------------------------------------------------------------------
# ORM Schema variables
# You should modify these based on deployment requirements.
# These default to recommended values
# --------------------------------------------------------------------------------------------------------------------- 


variable "enable_block_volumes" {
  default = "false"
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
variable "all" {
  default = "false"
}
variable "all_dbs" {
  default = "false"
}
variable "async" {
  default = "false"
}
variable "aws" {
  default = "false"
}
variable "azure" {
  default = "false"
}
variable "celery" {
  default = "false"
}
variable "cloudant" {
  default = "false"
}
variable "crypto" {
  default = "false"
}
variable "devel" {
  default = "false"
}
variable "devel_hadoop" {
  default = "false"
}
variable "druid" {
  default = "false"
}
variable "gcp" {
  default = "false"
}
variable "github_enterprise" {
  default = "false"
}
variable "google_auth" {
  default = "false"
}
variable "hashicorp" {
  default = "false"
}
variable "hdfs" {
  default = "false"
}
variable "hive" {
  default = "false"
}
variable "jdbc" {
  default = "false"
}
variable "kerberos" {
  default = "false"
}
variable "kubernetes" {
  default = "false"
}
variable "ldap" {
  default = "false"
}
variable "mssql" {
  default = "false"
}
variable "mysql" {
  default = "true"
}
variable "oracle" {
  default = "true"
}
variable "password" {
  default = "false"
}
variable "postgres" {
  default = "false"
}
variable "presto" {
  default = "false"
}
variable "qds" {
  default = "false"
}
variable "rabbitmq" {
  default = "false"
}
variable "redis" {
  default = "false"
}
variable "samba" {
  default = "false"
}
variable "slack" {
  default = "false"
}
variable "ssh" {
  default = "true"
}
variable "vertica" {
  default = "false"
}

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

// See https://docs.cloud.oracle.com/en-us/iaas/images/image/0c6332bc-a5ec-4ddf-99b8-5f33b0bc461a/
// Oracle-provided image "Oracle-Linux-7.8-2020.067.30-0"
// Kernel Version: 4.14.35-1902.303.5.3.el7uek.x86_64 
variable "OELImageOCID" {
  type = "map"
  default = {
    ap-chuncheon-1 = "ocid1.image.oc1.ap-chuncheon-1.aaaaaaaah4qawhzex2soci4bdfu5rmtqxum5meq246mmehiwf6foenccxt7a"
    ap-hyderabad-1 = "ocid1.image.oc1.ap-hyderabad-1.aaaaaaaan7b4rtk3fzr65o4y26cerr64zepillnkt7nkb7v2pixnstkhj4zq"
    ap-melbourne-1 = "ocid1.image.oc1.ap-melbourne-1.aaaaaaaahzx72p5mf66rdmbxxdvf225qt6t3cmhy5ogsnujsrs24wzfhvrxa"
    ap-mumbai-1 = "ocid1.image.oc1.ap-mumbai-1.aaaaaaaakiw6ctx53lo3vl6an6yqpfiljv3kml4a7yk3footssw5no72mqdq"
    ap-osaka-1 = "ocid1.image.oc1.ap-osaka-1.aaaaaaaaglv2o3dt75xk3mndbu4ol53m5g4bwdj6a2eloptpplhgv4pz4fga"
    ap-seoul-1 = "ocid1.image.oc1.ap-seoul-1.aaaaaaaapsrckrt4jvac7453pkajcrstg2nkv4a6cplvs5qkxjaowhrtuppa"
    ap-sydney-1 = "ocid1.image.oc1.ap-sydney-1.aaaaaaaacgkmddzqa6eyuqdlj3ackoj7bkckzewd65u473qigbgik4ffjkrq"
    ap-tokyo-1 = "ocid1.image.oc1.ap-tokyo-1.aaaaaaaag27ttaewtise5v2gjc3762n4rpovfb3v6vq2a6x2fnwhczmsmmha"
    ca-montreal-1 = "ocid1.image.oc1.ca-montreal-1.aaaaaaaacvixkp2ptverv3apol6w43aa7kn7b3uvvdcnn2pyfidlhosiieoq"
    ca-toronto-1 = "ocid1.image.oc1.ca-toronto-1.aaaaaaaarafs3f23oihrekl4p2hfyb5in46nbzlbrtmpyqkeybddlzgpl2fa"
    eu-amsterdam-1 = "ocid1.image.oc1.eu-amsterdam-1.aaaaaaaamy6nj5osieovhuegqncihbulhlefbquqtzcuumwpid3vskob6pea"
    eu-frankfurt-1 = "ocid1.image.oc1.eu-frankfurt-1.aaaaaaaaulz7xiht632iidvdm4iezy33fofulmerq2nkllwnkjy335qkswza"
    eu-zurich-1 = "ocid1.image.oc1.eu-zurich-1.aaaaaaaaz7iyv6tkydbtevjktdhunsxeez3vs4mk6gngel7qj2ymtto6ehwq"
    me-jeddah-1 = "ocid1.image.oc1.me-jeddah-1.aaaaaaaa3xm4dq6r67rdslmszygbemxbn2ojabhrj5op3vmpel4zc7cl4ssq"
    sa-saopaulo-1 = "ocid1.image.oc1.sa-saopaulo-1.aaaaaaaakndmtcb6ycz6mffgklqctnlb3bzr2pqo6a3jor762kr4hpsjodya"
    uk-gov-london-1 = "ocid1.image.oc4.uk-gov-london-1.aaaaaaaacap4psxhmmdghsb37ost57hmmfeeotm6c3cgi7pyekxdlzh3jlvq"
    uk-london-1 = "ocid1.image.oc1.uk-london-1.aaaaaaaayt6ppuyj6q4dwb4pkkyy3llrhxntywewfk4ssd365d4cn22i6yxa"
    us-ashburn-1 = "ocid1.image.oc1.iad.aaaaaaaabip6l5i5ikqsnm64xwrw2rrkj3tzo2dv47frowlt3droliwpvfaa"
    us-gov-ashburn-1 = "ocid1.image.oc3.us-gov-ashburn-1.aaaaaaaa44cyvmq7hjawqc6pkdczt5kpbakvsoj55talodxbvmhpjecit77a"
    us-gov-chicago-1 = "ocid1.image.oc3.us-gov-chicago-1.aaaaaaaaaht7f6ddqmuu2jhtp5bnrspbdsav6atbvdt43coql26dspjsffra"
    us-gov-phoenix-1 = "ocid1.image.oc3.us-gov-phoenix-1.aaaaaaaa33nckkwzxg65dwe3qwed6hc3zmza777vt6xom5xn3s7q2wneovea"
    us-langley-1 = "ocid1.image.oc2.us-langley-1.aaaaaaaazy4hfwcuxqsupcy75y6vjvmaoet5ns4rb2hlp3m2d6memcv2r2va"
    us-luke-1 = "ocid1.image.oc2.us-luke-1.aaaaaaaamvtduzihoo4cpury4dh2dghi74xf7hprpaotq6dyv5zoolkadira"
    us-phoenix-1 = "ocid1.image.oc1.phx.aaaaaaaaxdwzaqqvxvmyznmcx2n766fxatd6owcojqapkih7oqq4qt3o4wwa"
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

