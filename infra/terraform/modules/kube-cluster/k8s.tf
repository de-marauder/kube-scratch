module "manifests" {
  source = "../k8s-manifests"

  email        = var.email
  domain_name  = var.domain_name
  cluster_name = var.cluster_name
  alb_arn      = aws_lb.kube_load_balancer.arn
  alb_name     = aws_lb.kube_load_balancer.name
  region       = var.region
  asg_name     = local.asg_name
  vpc_id       = aws_vpc.kube_vpc.id

  cluster_autoscaler_role_arn = aws_iam_role.cluster_worker_role.arn

  grafana_password = var.grafana_password

  providers = {
    kubectl = kubectl
  }
}
