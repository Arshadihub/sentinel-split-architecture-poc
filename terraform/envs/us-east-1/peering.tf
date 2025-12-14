module "vpc_peering" {
  source = "../modules/peering"

  requester_vpc_id       = module.vpc_gateway.vpc_id
  accepter_vpc_id        = module.vpc_backend.vpc_id
  region                 = "us-east-1"
  gateway_private_rtb_id = module.vpc_gateway.private_route_table_id
  backend_private_rtb_id = module.vpc_backend.private_route_table_id
  gateway_cidr           = module.vpc_gateway.cidr
  backend_cidr           = module.vpc_backend.cidr
}
