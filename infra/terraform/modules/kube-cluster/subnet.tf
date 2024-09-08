# Subnet
resource "aws_subnet" "kube_subnet_private" {
  for_each = var.priv_subnet

  vpc_id            = aws_vpc.kube_vpc.id
  cidr_block        = each.value.cidr_block
  availability_zone = each.value.az

  tags = {
    Name = "kube-subnet-private"
  }
}

resource "aws_subnet" "kube_subnet_public" {
  for_each = var.pub_subnet

  vpc_id            = aws_vpc.kube_vpc.id
  cidr_block        = each.value.cidr_block
  availability_zone = each.value.az

  map_public_ip_on_launch = true

  tags = {
    Name = "kube-subnet-public"
  }
}

locals {
  private_subnet_ids = [for s in aws_subnet.kube_subnet_private : s.id]
  public_subnet_ids  = [for s in aws_subnet.kube_subnet_public : s.id]
}