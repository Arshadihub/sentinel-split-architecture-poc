variable "requester_vpc_id" {
  description = "VPC ID of the requester"
  type        = string
}

variable "accepter_vpc_id" {
  description = "VPC ID of the accepter"
  type        = string
}

variable "gateway_private_rtb_ids" {
  description = "Private route table IDs for gateway VPC"
  type        = list(string)
}

variable "backend_private_rtb_ids" {
  description = "Private route table IDs for backend VPC"
  type        = list(string)
}

variable "gateway_cidr" {
  description = "CIDR block of gateway VPC"
  type        = string
}

variable "backend_cidr" {
  description = "CIDR block of backend VPC"
  type        = string
}
