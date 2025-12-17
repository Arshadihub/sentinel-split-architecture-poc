provider "aws" {
  region = "us-east-1"
}

# Get cluster data for kubernetes providers
data "aws_eks_cluster" "backend" {
  name = "eks-backend"
}

data "aws_eks_cluster_auth" "backend" {
  name = "eks-backend"
}

data "aws_eks_cluster" "gateway" {
  name = "eks-gateway"
}

data "aws_eks_cluster_auth" "gateway" {
  name = "eks-gateway"
}

# Kubernetes provider for backend cluster
provider "kubernetes" {
  alias = "backend"
  
  host                   = data.aws_eks_cluster.backend.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.backend.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.backend.token
}

# Kubernetes provider for gateway cluster  
provider "kubernetes" {
  alias = "gateway"
  
  host                   = data.aws_eks_cluster.gateway.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.gateway.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.gateway.token
}
