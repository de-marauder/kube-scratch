# Create a Kubernetes Cluster with k3s and terraform on AWS
This directory contains terraform code required to spin up resources required to run your own kubernetes cluster using k3s. All nodes run ubuntu OS and are of type t3.medium by default.

## Requirements
- terraform
- AWS CLI configured for a terraform AWS IAM user


## How to use
1. Initiate terraform
   ```bash
   terraform init
   ```
2. Create a terraform.tfvars file at the root of the terraform folder
   ```bash
   cat <EOF > terraform.tfvars
   email            = "xxxxxxxxxx@gmail.com"
   domain_name      = "xxxxxx.@"
   grafana_password = "admin_password" # Change this to a secure password

   EOF
   ```

3. Make a Plan to view resources being provisioned
   ```bash
   terraform plan
   ```

4. Provision planned infrastructure (`-auto-approve` executes the command in non-interactive mode)
   ```bash
   terraform apply -auto-approve
   ```

## How it works
The core components of the infrastructure are:
1. The master node
2. The worker nodes
3. Dedicated Application Load balancer
4. Security groups
5. Multi-zonal subnets for High Availability
6. Virtual Private Cloud VPC network

The master node is assigned a dedicated elastic IP and the k3s server is started on it by passing the relevant flags information.

The worker nodes are managed by an auto scaling group. The ASG makes us of a launch template to provision the nodes when needed (i.e. when a node dies). 

The cluster autoscaler makes use of this ASG to scale the cluster based on pod resource requirements. To implement this functionality, the worker nodes are granted an IAM role attached to policies that give them the privilege to call the APIs required to scale the cluster.

A dedicated load balancer was required to effectively manage ingress. It is used in conjunction with ingress-nginx helm chart and aws-loadbalancer-controller to provide pod based routing from domain names. The setup also required some policies to be attached to the worker nodes so that they could call the relevant AWS APIs

Security groups were used to regulate access to the cluster nodes. Closing down all ports except 6443, 22, 80, and 443.

Port 6443 needed to be open on the master node so that the API server would be accessible from allowed CIDR ranges

Port 22 was opened to allow SSH access from allowed CIDR ranges. This can be closed down when not required for troubleshooting

Ports 80 and 443 need to be open to allow HTTP and HTTPs traffic respectively.

Subnets are provisioned in different availability zones so that each subnet can house a node thus providing high availability. There was one public subnet which housed a NAT gateway and the master node since it needed to be accessible over the internet. An alternative would have been to have a bastion which would exist in the VPC and public subnet. Kubectl commands would then be run from this bastion and the master node can be locked down in a private subnet. All workers nodes are in private subnets and access the internet via the NAT gateway

A VPC was created to isolate the entire infrastructure in a dedicated logical network.
