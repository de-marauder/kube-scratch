# Create an IAM Role for the Cluster worker
resource "aws_iam_role" "cluster_worker_role" {
  name = "cluster-worker-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

# Create a policy to the role that allows worker to modify EC2 Auto Scaling Groups and load balancers
resource "aws_iam_policy" "cluster_worker_policy" {
  name        = "cluster-worker-policy"
  description = "Policy for Cluster worker to modify EC2 Auto Scaling Groups and LoadBalancers"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow"
        Action = [
          # auto-scaling
          "autoscaling:DescribeAutoScalingGroups",
          "autoscaling:DescribeAutoScalingInstances",
          "autoscaling:DescribeLaunchConfigurations",
          "autoscaling:DescribeScalingActivities",
          "autoscaling:DescribeTags",
          "autoscaling:SetDesiredCapacity",
          "autoscaling:TerminateInstanceInAutoScalingGroup",
          "ec2:DescribeImages",
          "ec2:DescribeInstanceTypes",
          "ec2:DescribeLaunchTemplateVersions",
          "ec2:GetInstanceTypesFromInstanceRequirements",
          # loadBalancing
          "iam:CreateServiceLinkedRole",
          "ec2:DescribeInstances",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeSubnets",
          "ec2:DescribeVpcs",
          "elasticloadbalancing:*",
          "tag:GetResources",
          "tag:TagResources",
        ]
        Resource = "*"
      }
    ]
  })
}

# Attach the policy to the role
resource "aws_iam_role_policy_attachment" "cluster_worker_policy_attachment" {
  role       = aws_iam_role.cluster_worker_role.name
  policy_arn = aws_iam_policy.cluster_worker_policy.arn
}

# Create an IAM Role (instance profile) for the Cluster Instance
resource "aws_iam_instance_profile" "worker_instance_profile" {
  name = "WorkerInstanceProfile"
  role = aws_iam_role.cluster_worker_role.name
}
