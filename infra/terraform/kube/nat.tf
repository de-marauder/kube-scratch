# Create a NAT gateway
resource "aws_nat_gateway" "kube_nat_gateway" {
  allocation_id = aws_eip.kube_eip.id
  subnet_id     = local.public_subnet_ids[0]

  tags = {
    Name = "${var.cluster_name}-nat-gw",
  }
}

# Create Elastic IP for the NAT
resource "aws_eip" "kube_eip" {
  domain = "vpc"

  tags = {
    Name = "${var.cluster_name}-nat-eip",
  }
}
