data "aws_vpc" "existing" {
  count = var.use_existing_vpc_id != "" ? 1 : 0
  id    = var.use_existing_vpc_id
}

data "aws_subnets" "existing_public" {
  count = var.use_existing_vpc_id != "" ? 1 : 0
  filter {
    name   = "vpc-id"
    values = [var.use_existing_vpc_id]
  }
  filter {
    name   = "tag:Name"
    values = ["*public*"]
  }
}

data "aws_subnets" "existing_private" {
  count = var.use_existing_vpc_id != "" ? 1 : 0
  filter {
    name   = "vpc-id"
    values = [var.use_existing_vpc_id]
  }
  filter {
    name   = "tag:Name"
    values = ["*private*"]
  }
}

data "aws_route_tables" "existing_private" {
  count = var.use_existing_vpc_id != "" ? 1 : 0
  vpc_id = var.use_existing_vpc_id
  filter {
    name   = "tag:Name"
    values = ["*private*"]
  }
}

resource "aws_vpc" "this" {
  count                = var.use_existing_vpc_id != "" ? 0 : 1
  cidr_block           = var.cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = { Name = var.name }
}

locals {
  vpc_id = var.use_existing_vpc_id != "" ? data.aws_vpc.existing[0].id : aws_vpc.this[0].id
  vpc_cidr = var.use_existing_vpc_id != "" ? data.aws_vpc.existing[0].cidr_block : var.cidr
}

// create public subnets for NAT gateways (only when creating new VPC)
resource "aws_subnet" "public" {
  count                   = var.use_existing_vpc_id != "" ? 0 : length(var.azs)
  vpc_id                  = local.vpc_id
  cidr_block              = cidrsubnet(var.cidr, 8, count.index)
  availability_zone       = element(var.azs, count.index)
  map_public_ip_on_launch = true
  tags = { Name = "${var.name}-public-${count.index}" }
}

// create private subnets in remaining CIDR space (only when creating new VPC)
resource "aws_subnet" "private" {
  count                   = var.use_existing_vpc_id != "" ? 0 : length(var.azs)
  vpc_id                  = local.vpc_id
  cidr_block              = cidrsubnet(var.cidr, 8, count.index + length(var.azs))
  availability_zone       = element(var.azs, count.index)
  map_public_ip_on_launch = false
  tags = { Name = "${var.name}-private-${count.index}" }
}

resource "aws_internet_gateway" "igw" {
  count  = var.use_existing_vpc_id != "" ? 0 : 1
  vpc_id = local.vpc_id
  tags = { Name = "${var.name}-igw" }
}

resource "aws_route_table" "public" {
  count  = var.use_existing_vpc_id != "" ? 0 : 1
  vpc_id = local.vpc_id
  tags = { Name = "${var.name}-public-rt" }
}

resource "aws_route" "public_internet" {
  count                  = var.use_existing_vpc_id != "" ? 0 : 1
  route_table_id         = aws_route_table.public[0].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw[0].id
}

resource "aws_route_table_association" "public_assoc" {
  count          = var.use_existing_vpc_id != "" ? 0 : length(var.azs)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public[0].id
}

// Allocate EIPs and create NAT Gateways in each AZ (only for new VPCs)
resource "aws_eip" "nat_eip" {
  count = var.use_existing_vpc_id != "" ? 0 : (var.single_nat_gateway ? 1 : length(var.azs))
  vpc   = true
}

resource "aws_nat_gateway" "nat" {
  count         = var.use_existing_vpc_id != "" ? 0 : (var.single_nat_gateway ? 1 : length(var.azs))
  allocation_id = aws_eip.nat_eip[min(count.index, length(aws_eip.nat_eip)-1)].id
  subnet_id     = aws_subnet.public[min(count.index, length(aws_subnet.public)-1)].id
  tags = { Name = "${var.name}-nat-${count.index}" }
}

// Private route tables (one per AZ) and associations to private subnets (only for new VPCs)
resource "aws_route_table" "private" {
  count  = var.use_existing_vpc_id != "" ? 0 : length(var.azs)
  vpc_id = local.vpc_id
  tags = { Name = "${var.name}-private-rt-${count.index}" }
}

resource "aws_route" "private_default" {
  count                   = var.use_existing_vpc_id != "" ? 0 : length(var.azs)
  route_table_id          = aws_route_table.private[count.index].id
  destination_cidr_block  = "0.0.0.0/0"
  nat_gateway_id          = aws_nat_gateway.nat[var.single_nat_gateway ? 0 : count.index].id
}

resource "aws_route_table_association" "private_assoc" {
  count          = var.use_existing_vpc_id != "" ? 0 : length(var.azs)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}

// Outputs
output "vpc_id" {
  value = local.vpc_id
}

output "cidr" {
  value = local.vpc_cidr
}

output "public_subnet_ids" {
  value = var.use_existing_vpc_id != "" ? data.aws_subnets.existing_public[0].ids : [for s in aws_subnet.public : s.id]
}

output "private_subnet_ids" {
  value = var.use_existing_vpc_id != "" ? data.aws_subnets.existing_private[0].ids : [for s in aws_subnet.private : s.id]
}

output "private_route_table_id" {
  value = var.use_existing_vpc_id != "" ? (length(data.aws_route_tables.existing_private[0].ids) > 0 ? data.aws_route_tables.existing_private[0].ids[0] : "") : aws_route_table.private[0].id
}

output "private_route_table_ids" {
  value = var.use_existing_vpc_id != "" ? data.aws_route_tables.existing_private[0].ids : [for rt in aws_route_table.private : rt.id]
}
