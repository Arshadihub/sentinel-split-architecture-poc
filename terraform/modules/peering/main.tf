resource "aws_vpc_peering_connection" "peer" {
  vpc_id      = var.requester_vpc_id
  peer_vpc_id = var.accepter_vpc_id
  auto_accept = true
  tags        = { Name = "gateway-backend-peering" }
}

resource "aws_route" "gateway_to_backend" {
  route_table_id            = var.gateway_private_rtb_id
  destination_cidr_block    = var.backend_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.peer.id
}

resource "aws_route" "backend_to_gateway" {
  route_table_id            = var.backend_private_rtb_id
  destination_cidr_block    = var.gateway_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.peer.id
}
