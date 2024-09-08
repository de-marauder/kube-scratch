# Create an internet gateway
resource "aws_internet_gateway" "kube_igw" {
  vpc_id = aws_vpc.kube_vpc.id

  tags = {
    Name = "${var.cluster_name}-igw",
  }
}