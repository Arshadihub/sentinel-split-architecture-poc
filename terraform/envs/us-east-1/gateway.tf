module "vpc_gateway" {
  source = "../../modules/vpc"

  name                  = "vpc-gateway"
  cidr                  = "172.16.0.0/16"
  azs                   = ["us-east-1a", "us-east-1b"]
  single_nat_gateway    = true
  # Create new VPC instead of using existing
  use_existing_vpc_id   = ""
}

# Force recreation of EKS cluster so GitHub Actions user is the creator
module "eks_gateway" {
  source       = "../../modules/eks"
  cluster_name = "eks-gateway-v2"
  vpc_id       = module.vpc_gateway.vpc_id
  subnet_ids   = module.vpc_gateway.private_subnet_ids
  env          = "gateway"
}


