module "vpc_backend" {
  source = "../modules/vpc"

  name = "vpc-backend"
  cidr = "10.20.0.0/16"
  azs  = ["us-east-1a", "us-east-1b"]
}

module "eks_backend" {
  source       = "../modules/eks"
  cluster_name = "eks-backend"
  vpc_id       = module.vpc_backend.vpc_id
  subnet_ids   = module.vpc_backend.private_subnet_ids
  env          = "backend"
}
