# Check if EKS cluster already exists
data "aws_eks_cluster" "existing_gateway" {
  count = 1
  name  = "eks-gateway"
}

locals {
  gateway_cluster_exists = can(data.aws_eks_cluster.existing_gateway[0].status)
}

module "vpc_gateway" {
  source = "../../modules/vpc"

  name                  = "vpc-gateway"
  cidr                  = "10.10.0.0/16"
  azs                   = ["us-east-1a", "us-east-1b"]
  single_nat_gateway    = true
  use_existing_vpc_id   = "vpc-0bfde9598df7ce192"
}

# Only create EKS module if cluster doesn't exist
module "eks_gateway" {
  count        = local.gateway_cluster_exists ? 0 : 1
  source       = "../../modules/eks"
  cluster_name = "eks-gateway"
  vpc_id       = module.vpc_gateway.vpc_id
  subnet_ids   = module.vpc_gateway.private_subnet_ids
  env          = "gateway"
}

# Create aws-auth ConfigMap for gateway cluster using kubectl
resource "null_resource" "gateway_aws_auth" {
  provisioner "local-exec" {
    command = <<-EOF
      # Wait for cluster to be ready
      sleep 30
      
      # Update kubeconfig
      aws eks update-kubeconfig --name eks-gateway --region us-east-1 --alias eks-gateway
      
      # Create aws-auth ConfigMap
      cat <<YAML | kubectl apply --validate=false -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: aws-auth
  namespace: kube-system
data:
  mapUsers: |
    - userarn: arn:aws:iam::721500739616:user/arshadcsinfo@gmail.com
      username: github-actions
      groups:
        - system:masters
YAML
    EOF
  }
  
  depends_on = [data.aws_eks_cluster.existing_gateway]
}
