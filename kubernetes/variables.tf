variable "aws_region" {}

variable "vpc_cidr_network" {}

variable "tag_environment" {}

variable "tag_project" {}

variable "zones" {
  default = {
    zone0 = "a"
    zone1 = "b"
    zone2 = "c"
  }
}

variable "public_cidr_hosts" {
  default = {
    zone0 = "16.0/20"
    zone1 = "48.0/20"
    zone2 = "80.0/20"
  }
}

# CoreOS-stable-1185.3.0-hvm
variable "coreos_ami" {
  default = {
    eu-west-1 = "ami-abebb5d8"
  }
}

variable "kubernetes_service_ip_range" {
  default = "10.3.0.0/16"
}

variable "kubernetes_service_ip" {
  default = "10.3.0.1"
}

variable "kubernetes_dns_service_ip" {
  default = "10.3.0.10"
}

variable "ebs_size" {}
variable "root_size" {}
variable "domain_name" {}

variable "shared_vpc_id" {
  default = "vpc-22ff6647"
}

variable "shared_vpc_cidr_block" {
  default = "10.25.0.0/16"
}

variable "shared_owner_id" {
  default = "123810501009"
}
