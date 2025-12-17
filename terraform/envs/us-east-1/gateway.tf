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

# Force recreation of EKS cluster so GitHub Actions user is the creator
module "eks_gateway" {
  source       = "../../modules/eks"
  cluster_name = "eks-gateway"
  vpc_id       = module.vpc_gateway.vpc_id
  subnet_ids   = module.vpc_gateway.private_subnet_ids
  env          = "gateway"
}


