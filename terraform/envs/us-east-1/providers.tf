provider "aws" {
  region = "us-east-1"
}

# Kubernetes provider for backend cluster
provider "kubernetes" {
  alias = "backend"
  
  host                   = length(module.eks_backend) > 0 ? module.eks_backend[0].cluster_endpoint : ""
  cluster_ca_certificate = length(module.eks_backend) > 0 ? base64decode(module.eks_backend[0].cluster_certificate_authority_data) : ""
  
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args = ["eks", "get-token", "--cluster-name", "eks-backend", "--region", "us-east-1"]
  }
}

# Kubernetes provider for gateway cluster  
provider "kubernetes" {
  alias = "gateway"
  
  host                   = length(module.eks_gateway) > 0 ? module.eks_gateway[0].cluster_endpoint : ""
  cluster_ca_certificate = length(module.eks_gateway) > 0 ? base64decode(module.eks_gateway[0].cluster_certificate_authority_data) : ""
  
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args = ["eks", "get-token", "--cluster-name", "eks-gateway", "--region", "us-east-1"]
  }
}
