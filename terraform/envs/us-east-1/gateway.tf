module "vpc_gateway" {
  source = "../../modules/vpc"

  name                  = "vpc-gateway"
  cidr                  = "10.10.0.0/16"
  azs                   = ["us-east-1a", "us-east-1b"]
  single_nat_gateway    = true
  use_existing_vpc_id   = "vpc-0bfde9598df7ce192"
}

module "eks_gateway" {
  source       = "../../modules/eks"
  cluster_name = "eks-gateway"
  vpc_id       = module.vpc_gateway.vpc_id
  subnet_ids   = module.vpc_gateway.private_subnet_ids
  env          = "gateway"
}
