variable "name" {
  description = "Name tag for resources"
  type        = string
}

variable "cidr" {
  description = "VPC CIDR block"
  type        = string
}

variable "azs" {
  description = "List of Availability Zones to use"
  type        = list(string)
}

variable "single_nat_gateway" {
  description = "If true, create a single NAT gateway for the VPC (reduces EIP usage). When false, creates one NAT per AZ."
  type        = bool
  default     = true
}

variable "use_existing_vpc_id" {
  description = "If provided, use this existing VPC ID instead of creating a new VPC"
  type        = string
  default     = ""
}
