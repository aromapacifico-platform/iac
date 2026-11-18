module "network" {
  source = "../../modules/network"

  name_prefix                  = local.name_prefix
  aws_region                   = var.aws_region
  vpc_cidr                     = var.vpc_cidr
  availability_zones           = var.availability_zones
  gateway_endpoint_policies    = local.gateway_endpoint_policies
  collection_center_department = var.collection_center_department
  transit_gateway_id           = var.transit_gateway_id
  s3_interface = var.s3_interface_security_group_id == null ? null : {
    security_group_id = var.s3_interface_security_group_id
    policy            = local.gateway_endpoint_policies["s3"]
  }
}


module "security" {
  source    = "../../modules/security"
  providers = { aws.project = aws }

  client      = var.client
  project     = var.project
  environment = var.environment

  vpc_id             = module.network.vpc_id
  private_subnet_ids = module.network.private_subnet_ids
  public_subnet_ids  = module.network.public_subnet_ids

  ingest_rule_name         = local.ingest_names.rule
  authorized_private_cidrs = var.security_network.authorized_private_cidrs
  visitor_cidr             = var.security_network.visitor_cidr
  log_authorized_cidr      = var.security_network.log_authorized_cidr
  drone_backup_cidrs       = var.security_network.drone_backup_cidrs
  admin_cidr               = var.security_network.admin_cidr
  dns_cidr                 = var.security_network.dns_cidr
  app_cidr                 = var.security_network.app_cidr
}

module "ingest" {
  source    = "../../modules/ingest"
  providers = { aws.project = aws }

  kms_key_arn     = module.security.kms_key_data_arn
  ingest_role_arn = module.security.role_ingest_arn

  aws_account_id = data.aws_caller_identity.current.account_id
  aws_region     = var.aws_region
  resource_names = local.ingest_names
  farm_id        = var.farm_id
  thing_name     = local.thing_name
}

# Exactly one farm pattern; adding farms is a separately scoped change.
module "farm" {
  source    = "../../modules/farm"
  providers = { aws.project = aws }

  farm_id            = var.farm_id
  thing_name         = local.thing_name
  policy_name        = module.ingest.policy_name
  certificate_csr    = var.farm_certificate_csr
  certificate_active = var.farm_certificate_active
}
