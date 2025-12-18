module "vpc_backend" {
  source = "../../modules/vpc"

  name                  = "vpc-backend"
  cidr                  = "172.17.0.0/16"
  azs                   = ["us-east-1a", "us-east-1b"]
  single_nat_gateway    = true
  # Create new VPC instead of using existing
  use_existing_vpc_id   = ""
}

# Force recreation of EKS cluster so GitHub Actions user is the creator
module "eks_backend" {
  source       = "../../modules/eks"
  cluster_name = "eks-backend"
  vpc_id       = module.vpc_backend.vpc_id
  subnet_ids   = module.vpc_backend.private_subnet_ids
  env          = "backend"
}

# Security group for backend internal LoadBalancer
resource "aws_security_group" "backend_lb_sg" {
  name        = "backend-lb-sg"
  description = "Allow only gateway VPC CIDR to access backend LB"
  vpc_id      = module.vpc_backend.vpc_id

  ingress {
    description      = "allow gateway CIDR on 8080"
    from_port        = 8080
    to_port          = 8080
    protocol         = "tcp"
    cidr_blocks      = ["172.16.0.0/16"]  # Gateway VPC CIDR
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
  value = aws_security_group.backend_lb_sg.id
}
