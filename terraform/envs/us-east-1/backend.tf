# Import existing EKS cluster if it exists
import {
  to = module.eks_backend.module.eks.aws_eks_cluster.this[0]
  id = "eks-backend"
}

module "vpc_backend" {
  source = "../../modules/vpc"

  name                  = "vpc-backend"
  cidr                  = "10.20.0.0/16"
  azs                   = ["us-east-1a", "us-east-1b"]
  single_nat_gateway    = true
  use_existing_vpc_id   = "vpc-00d6478acab308f77"
}

module "eks_backend" {
  source       = "../../modules/eks"
  cluster_name = "eks-backend"
  vpc_id       = module.vpc_backend.vpc_id
  subnet_ids   = module.vpc_backend.private_subnet_ids
  env          = "backend"
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
