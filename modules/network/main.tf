resource "oci_core_vcn" "data_vcn" {
  count = var.useExistingVcn ? 0 : 1
  cidr_block     = "${var.VPC_CIDR}"
  compartment_id = "${var.compartment_ocid}"
  display_name   = "data_vcn"
  dns_label      = "${var.vcn_dns_label}"
}

resource "oci_core_internet_gateway" "data_internet_gateway" {
  count = var.useExistingVcn ? 0 : 1
  compartment_id = "${var.compartment_ocid}"
  display_name   = "data_internet_gateway"
  vcn_id         = "${var.useExistingVcn ? var.custom_vcn[0] : oci_core_vcn.data_vcn.0.id}"
}

resource "oci_core_nat_gateway" "nat_gateway" {
  count = var.useExistingVcn ? 0 : 1
  compartment_id = "${var.compartment_ocid}"
  vcn_id         = "${var.useExistingVcn ? var.custom_vcn[0] : oci_core_vcn.data_vcn.0.id}"
  display_name   = "nat_gateway"
}

resource "oci_core_service_gateway" "data_service_gateway" {
  count = var.useExistingVcn ? 0 : 1
  compartment_id = "${var.compartment_ocid}"
  services {
    service_id = "${lookup(data.oci_core_services.all_svcs_moniker[count.index].services[0], "id")}"
  }
  vcn_id = "${var.useExistingVcn ? var.custom_vcn[0] : oci_core_vcn.data_vcn.0.id}"
  display_name = "Cloudera Service Gateway"
}

resource "oci_core_route_table" "RouteForComplete" {
  count = var.useExistingVcn ? 0 : 1
  compartment_id = "${var.compartment_ocid}"
  vcn_id         = "${var.useExistingVcn ? var.custom_vcn[0] : oci_core_vcn.data_vcn.0.id}"
  display_name   = "RouteTableForComplete"

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = "${oci_core_internet_gateway.data_internet_gateway.*.id[count.index]}"
  }
}

resource "oci_core_route_table" "private" {
  count = var.useExistingVcn ? 0 : 1
  compartment_id = "${var.compartment_ocid}"
  vcn_id         = "${var.useExistingVcn ? var.custom_vcn[0] : oci_core_vcn.data_vcn.0.id}"
  display_name   = "private"

  route_rules {
      destination       = "${var.oci_service_gateway}"
      destination_type  = "SERVICE_CIDR_BLOCK"
      network_entity_id = "${oci_core_service_gateway.data_service_gateway.*.id[count.index]}"
    }
  
  route_rules {
      destination       = "0.0.0.0/0"
      destination_type  = "CIDR_BLOCK"
      network_entity_id = "${oci_core_nat_gateway.nat_gateway.*.id[count.index]}"
    }
}

resource "oci_core_security_list" "PublicSubnet" {
  count = var.useExistingVcn ? 0 : 1
  compartment_id = "${var.compartment_ocid}"
  display_name   = "Public Subnet"
  vcn_id         = "${var.useExistingVcn ? var.custom_vcn[0] : oci_core_vcn.data_vcn.0.id}"

  egress_security_rules {
    destination = "0.0.0.0/0"
    protocol    = "6"
  }

  egress_security_rules {
    protocol = "17"
    destination = "0.0.0.0/0"

    udp_options {
      min = 111
      max = 111
    }
  }

  ingress_security_rules {
    tcp_options {
      max = 22
      min = 22
    }

    protocol = "6"
    source   = "0.0.0.0/0"
  }

  ingress_security_rules {
    tcp_options {
      max = 8080
      min = 8080
    }

    protocol = "6"
    source   = "0.0.0.0/0"
  }

  ingress_security_rules {
    tcp_options {
      max = 5555
      min = 5555
    }

    protocol = "6"
    source   = "0.0.0.0/0"
  }
 
  ingress_security_rules {
    protocol = "6"
    source   = "${var.VPC_CIDR}"
  }

  ingress_security_rules {
    tcp_options {
      min = 2048
      max = 2050
    }
    protocol = "6"
    source   = "${var.VPC_CIDR}"
  }

  ingress_security_rules {
    udp_options {
      min = 2048
      max = 2048
    }
    protocol = "17"
    source   = "${var.VPC_CIDR}"
  }

  ingress_security_rules {
    tcp_options {
      min = 111
      max = 111
    }
    protocol = "6"
    source   = "${var.VPC_CIDR}"
  }

  ingress_security_rules {
    udp_options {
      min = 111
      max = 111
    }
    protocol = "17"
    source   = "${var.VPC_CIDR}"
  }
}

resource "oci_core_security_list" "PrivateSubnet" {
  count = var.useExistingVcn ? 0 : 1
  compartment_id = "${var.compartment_ocid}"
  display_name   = "Private"
  vcn_id         = "${var.useExistingVcn ? var.custom_vcn[0] : oci_core_vcn.data_vcn.0.id}"

  egress_security_rules {
    destination = "0.0.0.0/0"
    protocol    = "6"
  }

  egress_security_rules {
    protocol    = "6"
    destination = "${var.VPC_CIDR}"
  }

  egress_security_rules {
    protocol = "17"
    destination = "0.0.0.0/0"

    udp_options {
      min = 111
      max = 111
    }
  } 

  ingress_security_rules {
    protocol = "6"
    source   = "${var.VPC_CIDR}"
  }

  ingress_security_rules {
    tcp_options {
      min = 2048
      max = 2050
    }
    protocol = "6"
    source   = "${var.VPC_CIDR}"
  }

  ingress_security_rules {
    udp_options {
      min = 2048
      max = 2048
    }
    protocol = "17"
    source   = "${var.VPC_CIDR}"
  }

  ingress_security_rules {
    tcp_options {
      min = 111
      max = 111
    }
    protocol = "6"
    source   = "${var.VPC_CIDR}"
  }

  ingress_security_rules {
    udp_options {
      min = 111
      max = 111
    }
    protocol = "17"
    source   = "${var.VPC_CIDR}"
  }
}

resource "oci_core_subnet" "public" {
  count = var.useExistingVcn ? 0 : 1
  availability_domain = "${var.availability_domain}"
  cidr_block          = "${cidrsubnet(var.VPC_CIDR, 8, 1)}"
  display_name        = "public"
  compartment_id      = "${var.compartment_ocid}"
  vcn_id              = "${var.useExistingVcn ? var.custom_vcn[0] : oci_core_vcn.data_vcn.0.id}"
  route_table_id      = "${oci_core_route_table.RouteForComplete[count.index].id}"
  security_list_ids   = ["${oci_core_security_list.PublicSubnet.*.id[count.index]}"]
  dhcp_options_id     = "${oci_core_vcn.data_vcn[count.index].default_dhcp_options_id}"
  dns_label           = "public"
}

resource "oci_core_subnet" "private" {
  count = var.useExistingVcn ? 0 : 1
  availability_domain = "${var.availability_domain}"
  cidr_block          = "${cidrsubnet(var.VPC_CIDR, 8, 2)}"
  display_name        = "private"
  compartment_id      = "${var.compartment_ocid}"
  vcn_id              = "${var.useExistingVcn ? var.custom_vcn[0] : oci_core_vcn.data_vcn.0.id}"
  route_table_id      = "${oci_core_route_table.private[count.index].id}"
  security_list_ids   = ["${oci_core_security_list.PrivateSubnet.*.id[count.index]}"]
  dhcp_options_id     = "${oci_core_vcn.data_vcn[count.index].default_dhcp_options_id}"
  prohibit_public_ip_on_vnic = "true"
  dns_label = "private"
}

