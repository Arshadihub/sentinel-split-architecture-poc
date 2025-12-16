variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where EKS will be deployed"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for EKS"
  type        = list(string)
}

variable "env" {
  description = "Environment label"
  type        = string
  default     = ""
}

variable "create_kms_key" {
  description = "Whether to create a KMS key for cluster encryption"
  type        = bool
  default     = false
}

variable "cluster_encryption_config" {
  description = "Cluster encryption config passed to the EKS module; set to [] to disable"
  type        = list(any)
  default     = []
}
