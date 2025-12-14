module "vpc_gateway" {
  source = "../../modules/vpc"

  name = "vpc-gateway"
  cidr = "10.10.0.0/16"
  azs  = ["us-east-1a", "us-east-1b"]
}

module "eks_gateway" {
  source       = "../../modules/eks"
  cluster_name = "eks-gateway"
  vpc_id       = module.vpc_gateway.vpc_id
  subnet_ids   = module.vpc_gateway.private_subnet_ids
  env          = "gateway"
}
