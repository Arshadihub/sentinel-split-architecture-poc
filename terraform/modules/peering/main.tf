resource "aws_vpc_peering_connection" "peer" {
  vpc_id      = var.requester_vpc_id
  peer_vpc_id = var.accepter_vpc_id
  auto_accept = true
  tags        = { Name = "gateway-backend-peering" }
}

# Check if routes already exist
data "aws_route_table" "gateway_private" {
  route_table_id = var.gateway_private_rtb_id
}

data "aws_route_table" "backend_private" {
  route_table_id = var.backend_private_rtb_id
}

locals {
  gateway_route_exists = contains([for route in data.aws_route_table.gateway_private.routes : route.destination_cidr_block], var.backend_cidr)
  backend_route_exists = contains([for route in data.aws_route_table.backend_private.routes : route.destination_cidr_block], var.gateway_cidr)
}

resource "aws_route" "gateway_to_backend" {
  count                     = local.gateway_route_exists ? 0 : 1
  route_table_id            = var.gateway_private_rtb_id
  destination_cidr_block    = var.backend_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.peer.id
}

resource "aws_route" "backend_to_gateway" {
  count                     = local.backend_route_exists ? 0 : 1
  route_table_id            = var.backend_private_rtb_id
  destination_cidr_block    = var.gateway_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.peer.id
}
