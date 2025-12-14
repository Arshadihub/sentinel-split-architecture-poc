variable "requester_vpc_id" {
  description = "VPC ID of the requester"
  type        = string
}

variable "accepter_vpc_id" {
  description = "VPC ID of the accepter"
  type        = string
}

variable "gateway_private_rtb_id" {
  description = "Private route table id for gateway VPC"
  type        = string
}

variable "backend_private_rtb_id" {
  description = "Private route table id for backend VPC"
  type        = string
}

variable "gateway_cidr" {
  description = "CIDR block of gateway VPC"
  type        = string
}

variable "backend_cidr" {
  description = "CIDR block of backend VPC"
  type        = string
}
