# Create Public Route Table
resource "aws_route_table" "kube_route_table_igw" {
  vpc_id = aws_vpc.kube_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.kube_igw.id
  }
  tags = {
    Name = "${var.cluster_name}-rtb-igw",
  }
}

resource "aws_route_table" "kube_route_table_nat" {
  vpc_id = aws_vpc.kube_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.kube_nat_gateway.id
  }

  tags = {
    Name = "${var.cluster_name}-rtb-nat",
  }
}

# Associate public subnet with public route table
resource "aws_route_table_association" "kube-rtb-pub-assoc" {
  for_each       = aws_subnet.kube_subnet_public
  subnet_id      = each.value.id
  route_table_id = aws_route_table.kube_route_table_igw.id
}

# Associate private subnet with nat gateway via route table
resource "aws_route_table_association" "kube-rtb-priv-assoc" {
  for_each       = aws_subnet.kube_subnet_private
  subnet_id      = each.value.id
  route_table_id = aws_route_table.kube_route_table_nat.id
}