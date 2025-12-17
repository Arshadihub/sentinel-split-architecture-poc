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

  # Disable KMS key creation/encryption by default for the PoC
  create_kms_key              = var.create_kms_key
  cluster_encryption_config   = var.cluster_encryption_config

  # Enable cluster creator admin permissions
  enable_cluster_creator_admin_permissions = true

  eks_managed_node_groups = {
    default = {
      min_size       = 2
      max_size       = 3
      desired_size   = 2
      instance_types = ["t3.medium"]
    }
  }
}

# Create aws-auth ConfigMap directly in terraform to ensure GitHub Actions user has access
resource "kubernetes_config_map_v1" "aws_auth" {
  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
  }

  data = {
    mapRoles = yamlencode([
      {
        rolearn  = module.eks.eks_managed_node_groups.default.iam_role_arn
        username = "system:node:{{EC2PrivateDNSName}}"
        groups = [
          "system:bootstrappers",
          "system:nodes"
        ]
      }
    ])
    mapUsers = yamlencode([
      {
        userarn  = "arn:aws:iam::721500739616:user/arshadcsinfo@gmail.com"
        username = "github-actions"
        groups   = ["system:masters"]
      }
    ])
  }

  depends_on = [module.eks.cluster_name]
}
