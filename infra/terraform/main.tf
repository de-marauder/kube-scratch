module "kube" {
  source = "./modules/kube-cluster"

  region              = var.region
  cluster_name        = var.cluster_name
  master_count        = var.master_count
  worker_count        = var.worker_count
  allowed_cidr_blocks = var.allowed_cidr_blocks
  domain_name         = var.domain_name
  email               = var.email
  grafana_password    = var.grafana_password

  providers = {
    aws = aws
  }
}

output "kube_params" {
  value = module.kube
}
