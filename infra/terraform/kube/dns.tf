# ########################################
# If managing DNS in AWS
# ########################################

# # get hosted zone details
# resource "aws_route53_zone" "hosted_zone" {
#   name = var.domain_name
#   tags = {
#     Name = "kube_hosted_zone"
#   }
# }

# # create a record set for the load balancer
# resource "aws_route53_record" "app_record" {
#   zone_id = aws_route53_zone.hosted_zone.zone_id
#   name    = "bird-api.${var.domain_name}"
#   type    = "A"
#   alias {
#     name                   = aws_lb.kube_load_balancer.dns_name
#     zone_id                = aws_lb.kube_load_balancer.zone_id
#     evaluate_target_health = true
#   }
# }
