resource "tls_private_key" "k3s_ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "k3s_key_pair" {
  key_name   = "k3s-key-pair"
  public_key = tls_private_key.k3s_ssh.public_key_openssh
}

resource "local_file" "ssh_private_key" {
  filename        = "${path.module}/k3s_ssh_key.pem"
  content         = tls_private_key.k3s_ssh.private_key_pem
  file_permission = "0400"
}