resource "aws_vpc_peering_connection" "peer" {
  vpc_id      = var.requester_vpc_id
  peer_vpc_id = var.accepter_vpc_id
  auto_accept = true
  tags        = { Name = "gateway-backend-peering" }
}

# Add route from gateway to backend in gateway private route tables
resource "aws_route" "gateway_to_backend" {
  for_each                  = toset(var.gateway_private_rtb_ids)
  route_table_id            = each.value
  destination_cidr_block    = var.backend_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.peer.id
}

# Add route from backend to gateway in backend private route tables
resource "aws_route" "backend_to_gateway" {
  for_each                  = toset(var.backend_private_rtb_ids)
  route_table_id            = each.value
  destination_cidr_block    = var.gateway_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.peer.id
}
