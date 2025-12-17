# Check if EKS cluster already exists
data "aws_eks_cluster" "existing_backend" {
  count = 1
  name  = "eks-backend"
}

locals {
  backend_cluster_exists = can(data.aws_eks_cluster.existing_backend[0].status)
}

module "vpc_backend" {
  source = "../../modules/vpc"

  name                  = "vpc-backend"
  cidr                  = "10.20.0.0/16"
  azs                   = ["us-east-1a", "us-east-1b"]
  single_nat_gateway    = true
  use_existing_vpc_id   = "vpc-00d6478acab308f77"
}

# Only create EKS module if cluster doesn't exist
module "eks_backend" {
  count        = local.backend_cluster_exists ? 0 : 1
  source       = "../../modules/eks"
  cluster_name = "eks-backend"
  vpc_id       = module.vpc_backend.vpc_id
  subnet_ids   = module.vpc_backend.private_subnet_ids
  env          = "backend"
}

# Create aws-auth ConfigMap for backend cluster
resource "kubernetes_config_map_v1" "backend_aws_auth" {
  count    = local.backend_cluster_exists ? 0 : 1
  provider = kubernetes.backend
  
  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
  }

  data = {
    mapRoles = yamlencode([
      {
        rolearn  = module.eks_backend[0].eks_managed_node_groups.default.iam_role_arn
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

  depends_on = [module.eks_backend]
}

# Data source to check if security group exists
data "aws_security_groups" "existing_backend_lb_sg" {
  filter {
    name   = "vpc-id"
    values = [module.vpc_backend.vpc_id]
  }
  filter {
    name   = "group-name"
    values = ["backend-lb-sg"]
  }
}

# Security group for backend internal LoadBalancer (conditional creation)
resource "aws_security_group" "backend_lb_sg" {
  count       = length(data.aws_security_groups.existing_backend_lb_sg.ids) == 0 ? 1 : 0
  name        = "backend-lb-sg"
  description = "Allow only gateway VPC CIDR to access backend LB"
  vpc_id      = module.vpc_backend.vpc_id

  ingress {
    description      = "allow gateway CIDR on 8080"
    from_port        = 8080
    to_port          = 8080
    protocol         = "tcp"
    cidr_blocks      = [module.vpc_gateway.cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "backend-lb-sg"
  }
}

output "backend_lb_sg_id" {
  value = length(data.aws_security_groups.existing_backend_lb_sg.ids) > 0 ? data.aws_security_groups.existing_backend_lb_sg.ids[0] : aws_security_group.backend_lb_sg[0].id
}
