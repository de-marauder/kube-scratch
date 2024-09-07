# Security groups for inter node communication and allowing restricted ssh access
resource "aws_security_group" "allow_k3s" {
  name        = "allow_k3s"
  description = "Allow k3s inbound traffic"
  vpc_id      = aws_vpc.kube_vpc.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
  }

  ingress {
    description = "K3s supervisor and kubernetes API"
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    self        = true
    cidr_blocks = var.allowed_cidr_blocks
  }
  ingress {
    description = "ALB Target group health check"
    from_port   = 0
    to_port     = 10254
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "K3s node-to-node communication"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_k3s"
  }
}

# Create a security group for the ingress load balancer
resource "aws_security_group" "kube_load_balancer_sg" {
  name        = "kube_load_balancer_sg"
  description = "Security group for the ingress load balancer"
  vpc_id      = aws_vpc.kube_vpc.id
  ingress {
    from_port   = 80
    to_port     = 80
    description = "HTTP"
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 443
    to_port     = 443
    description = "HTTPS"
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
