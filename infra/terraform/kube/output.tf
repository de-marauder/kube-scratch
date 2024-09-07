output "master_public_ip" {
  value = values(aws_instance.k3s_master)[*].public_ip
  # value = [for instance in aws_instance.k3s_master : instance.public_ip]
}

output "alb_public_dns" {
  value = aws_lb.kube_load_balancer.dns_name
}