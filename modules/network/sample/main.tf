module "network" {
  source = "../"

  providers = {
    aws.project = aws.principal
  }

  name_prefix                  = local.name_prefix
  aws_region                   = var.aws_region
  vpc_cidr                     = var.vpc_cidr
  availability_zones           = var.availability_zones
  gateway_endpoint_policies    = local.gateway_endpoint_policies
  collection_center_department = var.collection_center_department
}
