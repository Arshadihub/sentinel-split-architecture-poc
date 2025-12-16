resource "aws_vpc" "this" {
  cidr_block           = var.cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = { Name = var.name }
}

// create public subnets for NAT gateways
resource "aws_subnet" "public" {
  count                   = length(var.azs)
  vpc_id                  = aws_vpc.this.id
  cidr_block              = cidrsubnet(var.cidr, 8, count.index)
  availability_zone       = element(var.azs, count.index)
  map_public_ip_on_launch = true
  tags = { Name = "${var.name}-public-${count.index}" }
}

// create private subnets in remaining CIDR space
resource "aws_subnet" "private" {
  count                   = length(var.azs)
  vpc_id                  = aws_vpc.this.id
  cidr_block              = cidrsubnet(var.cidr, 8, count.index + length(var.azs))
  availability_zone       = element(var.azs, count.index)
  map_public_ip_on_launch = false
  tags = { Name = "${var.name}-private-${count.index}" }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.this.id
  tags = { Name = "${var.name}-igw" }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id
  tags = { Name = "${var.name}-public-rt" }
}

resource "aws_route" "public_internet" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

resource "aws_route_table_association" "public_assoc" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

// Allocate EIPs and create NAT Gateways in each AZ
resource "aws_eip" "nat_eip" {
  count = var.single_nat_gateway ? 1 : length(var.azs)
  vpc   = true
}

resource "aws_nat_gateway" "nat" {
  count         = var.single_nat_gateway ? 1 : length(var.azs)
  allocation_id = aws_eip.nat_eip[min(count.index, length(aws_eip.nat_eip)-1)].id
  subnet_id     = aws_subnet.public[min(count.index, length(aws_subnet.public)-1)].id
  tags = { Name = "${var.name}-nat-${count.index}" }
}

// Private route tables (one per AZ) and associations to private subnets
resource "aws_route_table" "private" {
  count  = length(var.azs)
  vpc_id = aws_vpc.this.id
  tags = { Name = "${var.name}-private-rt-${count.index}" }
}

resource "aws_route" "private_default" {
  count                   = length(var.azs)
  route_table_id          = aws_route_table.private[count.index].id
  destination_cidr_block  = "0.0.0.0/0"
  nat_gateway_id          = aws_nat_gateway.nat[var.single_nat_gateway ? 0 : count.index].id
}

resource "aws_route_table_association" "private_assoc" {
  count          = length(aws_subnet.private)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}

// Outputs
output "vpc_id" {
  value = aws_vpc.this.id
}

output "cidr" {
  value = var.cidr
}

output "public_subnet_ids" {
  value = [for s in aws_subnet.public : s.id]
}

output "private_subnet_ids" {
  value = [for s in aws_subnet.private : s.id]
}

output "private_route_table_id" {
  value = aws_route_table.private[0].id
}

output "private_route_table_ids" {
  value = [for rt in aws_route_table.private : rt.id]
}
