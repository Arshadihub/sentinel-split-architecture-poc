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
