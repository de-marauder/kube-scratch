# Create template to be used to create worker instances and install k3s agents (point agent to master node api-server)
resource "aws_launch_template" "k3s_worker_template" {
  name          = "k3s-worker-template"
  image_id      = data.aws_ami.ubuntu.id
  instance_type = "t3.small"
  key_name      = aws_key_pair.k3s_key_pair.key_name

  network_interfaces {
    associate_public_ip_address = false
    subnet_id                   = local.private_subnet_ids[0]
    security_groups             = [aws_security_group.allow_k3s.id]
  }

  iam_instance_profile {
    name = aws_iam_instance_profile.worker_instance_profile.name
  }

  user_data = base64encode(<<-EOF
    #!/bin/bash
    curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="agent \
      --server=https://${aws_instance.k3s_master[1].private_ip}:6443 \
      --token=${random_password.k3s_token.result} \
      --node-name=${var.cluster_name}-worker \
      --with-node-id" sh -
  EOF
  )

}


# Create highly available worker node autoscaling group by providing subnet list in `vpc_zone_identifier`
resource "aws_autoscaling_group" "k3s_asg" {
  name             = local.asg_name
  desired_capacity = 2
  max_size         = 5
  min_size         = 1
  launch_template {
    id      = aws_launch_template.k3s_worker_template.id
    version = "$Latest"
  }
  vpc_zone_identifier       = local.private_subnet_ids
  health_check_type         = "EC2"
  health_check_grace_period = 300
  target_group_arns         = [aws_lb_target_group.kube_target_group.arn]

  tag {
    key                 = "Name"
    value               = "k3s-worker-node"
    propagate_at_launch = true
  }
  tag {
    key                 = "k8s.io/cluster-autoscaler/enabled"
    value               = "true"
    propagate_at_launch = true
  }
  tag {
    key                 = "k8s.io/cluster-autoscaler/${var.cluster_name}"
    value               = "owned"
    propagate_at_launch = true
  }
}

locals {
  asg_name = "${var.cluster_name}-node-asg"
}
