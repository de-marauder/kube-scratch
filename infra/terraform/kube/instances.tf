# get ubuntu ami id
data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

# Create Elastic IP
resource "aws_eip" "kube_master_eip" {
  for_each = aws_subnet.kube_subnet_public
  domain   = "vpc"
  tags = {
    Name = "${var.cluster_name}-master-${each.key}-eip",
  }
}

# Associate Elastic IP with EC2 instance
resource "aws_eip_association" "k3s_master_ip_assoc" {
  instance_id   = aws_instance.k3s_master[1].id
  allocation_id = aws_eip.kube_master_eip[1].id
}

resource "aws_instance" "k3s_master" {
  for_each      = aws_subnet.kube_subnet_public
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.medium"
  key_name      = aws_key_pair.k3s_key_pair.key_name

  vpc_security_group_ids = [aws_security_group.allow_k3s.id]
  subnet_id              = each.value.id

  tags = {
    Name = "k3s-master-node-${each.key}"
  }
}

resource "random_password" "k3s_token" {
  length  = 16
  special = false
}

# Install k3s server
resource "null_resource" "add_master_privateIP_to_cert" {
  depends_on = [aws_instance.k3s_master, aws_eip_association.k3s_master_ip_assoc]

  provisioner "local-exec" {
    command = <<EOT
      ssh -i ${local_file.ssh_private_key.filename} -o StrictHostKeyChecking=no ubuntu@${aws_eip.kube_master_eip[1].public_ip} '
      export K3S_CLUSTER_NAME=${var.cluster_name}
      curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="server \
        --disable=traefik \ # default k3s Ingress controller
        --tls-san=${aws_eip.kube_master_eip[1].public_ip} \ # IP address to sign on kubeconfig certificates
        --tls-san=${aws_instance.k3s_master[1].private_ip} \ # IP address to sign on kubeconfig certificates
        --node-name=${var.cluster_name}-master \
        --pod-eviction-timeout=1h \ # Period of node inactivity before its pods are deleted 
        --token=${random_password.k3s_token.result}" sh -
      '
    EOT
  }
}

# Get kubeconfig file from master server and save on local machine
resource "null_resource" "retrieve_kubeconfig" {
  depends_on = [aws_instance.k3s_master, null_resource.add_master_privateIP_to_cert]

  provisioner "local-exec" {
    command = "ssh -i ${local_file.ssh_private_key.filename} -o StrictHostKeyChecking=no ubuntu@${aws_instance.k3s_master[1].public_ip} 'sleep 10 && sudo cat /etc/rancher/k3s/k3s.yaml' > ${path.module}/kubeconfig_old.yaml"
  }
}

# Get saved kubeconfig from local machine
data "local_file" "kubeconfig_old" {
  depends_on = [null_resource.retrieve_kubeconfig]
  filename   = "${path.module}/kubeconfig_old.yaml"
}


# Update kubeconfig file with master's public IP address (k3s creates a kubeconfig with host as localhost)
resource "local_file" "kubeconfig" {
  filename = "${path.module}/kubeconfig.yaml"
  content  = replace(data.local_file.kubeconfig_old.content, "127.0.0.1", aws_eip.kube_master_eip[1].public_ip)
}
