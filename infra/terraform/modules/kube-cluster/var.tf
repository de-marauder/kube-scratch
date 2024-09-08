variable "region" {}

variable "cluster_name" {}

variable "master_count" {}

variable "worker_count" {}

variable "allowed_cidr_blocks" {}

variable "email" {}

variable "domain_name" {}

variable "grafana_password" {}

variable "vpc_cidr" {
  default = "10.0.0.0/16"
}

variable "pub_subnet" {
  default = {
    1 = {
      cidr_block = "10.0.10.0/24"
      az         = "us-east-1c"
    }
  }
}

variable "priv_subnet" {
  default = {
    1 = {
      cidr_block = "10.0.1.0/24"
      az         = "us-east-1a"
    }
    2 = {
      cidr_block = "10.0.2.0/24"
      az         = "us-east-1b"
    }
  }
}
