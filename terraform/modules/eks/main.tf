module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  version         = "20.8.5"
  cluster_name    = var.cluster_name
  cluster_version = "1.29"
  vpc_id          = var.vpc_id
  subnet_ids      = var.subnet_ids
  enable_irsa     = true

  # Enable public endpoint access for CI/CD
  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = true
  cluster_endpoint_public_access_cidrs = ["0.0.0.0/0"]

  # Configure aws-auth ConfigMap to allow GitHub Actions IAM user
  manage_aws_auth_configmap = true
  aws_auth_users = [
    {
      userarn  = "arn:aws:iam::721500739616:user/arshadcsinfo@gmail.com"
      username = "github-actions"
      groups   = ["system:masters"]
    }
  ]

  # Disable KMS key creation/encryption by default for the PoC
  create_kms_key              = var.create_kms_key
  cluster_encryption_config   = var.cluster_encryption_config

  eks_managed_node_groups = {
    default = {
      min_size       = 2
      max_size       = 3
      desired_size   = 2
      instance_types = ["t3.medium"]
    }
  }
}
