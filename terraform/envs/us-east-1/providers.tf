provider "aws" {
  region = "us-east-1"
}

provider "kubernetes" {
  host                   = module.eks_backend.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks_backend.cluster_certificate_authority_data)
  
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args = ["eks", "get-token", "--cluster-name", module.eks_backend.cluster_name, "--region", "us-east-1"]
  }
}
