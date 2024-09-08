# Create an Application Load Balancer for Kubernetes ingress
resource "aws_lb" "kube_load_balancer" {
  name               = "kube-load-balancer"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.kube_load_balancer_sg.id]
  subnets = concat(
    local.private_subnet_ids,
    local.public_subnet_ids
  )
  enable_deletion_protection = false
  depends_on                 = [aws_instance.k3s_master]
}

# Create the target group
resource "aws_lb_target_group" "kube_target_group" {
  name        = "kube-target-group"
  target_type = "instance"
  port        = 10254
  protocol    = "HTTP"
  vpc_id      = aws_vpc.kube_vpc.id
  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 15
    timeout             = 3
    healthy_threshold   = 3
    unhealthy_threshold = 3
  }
}

# Create the listener
resource "aws_lb_listener" "kube_listener" {
  load_balancer_arn = aws_lb.kube_load_balancer.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.kube_target_group.arn
  }
}

# Create the listener rule
resource "aws_lb_listener_rule" "kube_listener_rule" {
  listener_arn = aws_lb_listener.kube_listener.arn
  priority     = 1
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.kube_target_group.arn
  }
  condition {
    path_pattern {
      values = ["/"]
    }
  }
}

# Attach the target group to the load balancer
resource "aws_lb_target_group_attachment" "k3s-master" {
  for_each         = aws_instance.k3s_master
  target_group_arn = aws_lb_target_group.kube_target_group.arn
  target_id        = each.value.id
  port             = 80
}
