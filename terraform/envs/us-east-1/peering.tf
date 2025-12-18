module "vpc_peering" {
  source = "../../modules/peering"

  requester_vpc_id         = module.vpc_gateway.vpc_id
  accepter_vpc_id          = module.vpc_backend.vpc_id
  gateway_private_rtb_ids  = module.vpc_gateway.private_route_table_ids
  backend_private_rtb_ids  = module.vpc_backend.private_route_table_ids
  gateway_cidr             = module.vpc_gateway.cidr
  backend_cidr             = module.vpc_backend.cidr

  # Only create peering after VPCs are ready
  depends_on = [
    module.vpc_gateway,
    module.vpc_backend
  ]
}
