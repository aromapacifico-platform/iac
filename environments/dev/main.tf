module "network" {
  # A. Source
  source = "../../modules/network"

  # B. Providers (PC-IAC-005)
  providers = {
    aws.project = aws.principal
  }

  # D. Transversal configuration
  aws_region                   = var.aws_region
  vpc_cidr                     = var.vpc_cidr
  availability_zones           = var.availability_zones
  collection_center_department = var.collection_center_department
  transit_gateway_id           = var.transit_gateway_id

  # E. Resource-specific configuration
  name_prefix               = local.name_prefix
  gateway_endpoint_policies = local.gateway_endpoint_policies
  s3_interface = var.s3_interface_security_group_id == null ? null : {
    security_group_id = var.s3_interface_security_group_id
    policy            = local.gateway_endpoint_policies["s3"]
  }
}

module "security" {
  # A. Source
  source = "../../modules/security"

  # B. Providers (PC-IAC-005)
  providers = {
    aws.project = aws.principal
  }

  # C. Governance variables
  client      = var.client
  project     = var.project
  environment = var.environment

  # D. Transversal variables
  vpc_id             = module.network.vpc_id
  private_subnet_ids = module.network.private_subnet_ids
  public_subnet_ids  = module.network.public_subnet_ids

  # E. Resource-specific configuration
  name_prefix              = local.security_prefix
  ingest_rule_name         = local.ingest_names.rule
  focus_function_name      = local.focus_function_name
  authorized_private_cidrs = var.security_network.authorized_private_cidrs
  visitor_cidr             = var.security_network.visitor_cidr
  log_authorized_cidr      = var.security_network.log_authorized_cidr
  drone_backup_cidrs       = var.security_network.drone_backup_cidrs
  admin_cidr               = var.security_network.admin_cidr
  dns_cidr                 = var.security_network.dns_cidr
  app_cidr                 = var.security_network.app_cidr
}

module "ingest" {
  # A. Source
  source = "../../modules/ingest"

  # B. Providers (PC-IAC-005)
  providers = {
    aws.project = aws.principal
  }

  # D. Transversal variables
  kms_key_arn     = module.security.kms_key_data_arn
  ingest_role_arn = module.security.role_ingest_arn
  aws_account_id  = data.aws_caller_identity.current.account_id
  aws_region      = var.aws_region

  # E. Resource-specific configuration
  resource_names = local.ingest_names
  farm_id        = var.farm_id
  thing_name     = local.thing_name
}

# Exactly one farm pattern; adding farms is a separately scoped change.
module "farm" {
  # A. Source
  source = "../../modules/farm"

  # B. Providers (PC-IAC-005)
  providers = {
    aws.project = aws.principal
  }

  # E. Resource-specific configuration
  farm_id            = var.farm_id
  thing_name         = local.thing_name
  policy_name        = module.ingest.policy_name
  certificate_csr    = var.farm_certificate_csr
  certificate_active = var.farm_certificate_active
}

module "function" {
  # A. Source
  source = "../../modules/function"

  # B. Providers (PC-IAC-005)
  providers = {
    aws.project = aws.principal
  }

  # C. Governance variables
  client      = var.client
  project     = var.project
  environment = var.environment

  # D. Transversal variables (PC-IAC-022: consume security & network outputs)
  kms_key_objects_arn = module.security.kms_key_objects_arn
  kms_key_data_arn    = module.security.kms_key_data_arn
  kms_key_logs_arn    = module.security.kms_key_logs_arn
  iam_role_arn        = module.security.role_focus_function_arn
  subnet_ids          = module.network.function_subnet_ids
  security_group_ids  = [module.security.security_group_ids["function"]]

  # E. Resource-specific configuration
  name_prefix            = local.security_prefix
  expedientes_table_name = local.expedientes_table_name
}
