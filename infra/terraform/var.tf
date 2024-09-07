variable "email" { 
  description = "Email address for SSL certificate"
}

variable "cluster_name" {
  default = "kube-cluster"
}

variable "region" {
  default = "us-east-1"
}

variable "master_count" {
  default     = 1
  description = "Number of master nodes in the cluster"
}

variable "worker_count" {
  default     = 2
  description = "Number of worker nodes in the cluster"
}

variable "allowed_cidr_blocks" {
  default     = ["0.0.0.0/0"] # Tighten up to include only specific CIDR
  # default = ["105.112.220.120/32"]
  description = "CIDR range to allow access to the cluster"
}

variable "domain_name" {
  description = "FQDN for Ingress definitions in the cluster"
}

variable "grafana_password" {
  default = "admin_password"  # Change this to a secure password
}