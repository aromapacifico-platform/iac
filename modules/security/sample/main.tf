# Module invocation strictly complying with PC-IAC-013, PC-IAC-021, PC-IAC-026
module "security" {
  # Section A: source and version
  source = "../"

  # Section B: providers mapping
  providers = {
    aws.project = aws.principal
  }

  # Section C: governance variables
  client      = local.client
  project     = local.project
  environment = local.environment

  # Section D: transversal infrastructure dependencies
  vpc_id             = var.vpc_id
  private_subnet_ids = var.private_subnet_ids
  public_subnet_ids  = var.public_subnet_ids

  # Section E: resource specific configurations
  name_prefix                 = local.name_prefix
  ingest_rule_name            = local.ingest_rule_name
  focus_function_name         = local.focus_function_name
  authorized_private_cidrs    = var.authorized_private_cidrs
  visitor_cidr                = var.visitor_cidr
  log_authorized_cidr         = var.log_authorized_cidr
  drone_backup_cidrs          = var.drone_backup_cidrs
  admin_cidr                  = var.admin_cidr
  dns_cidr                    = var.dns_cidr
  app_cidr                    = var.app_cidr
  kms_deletion_window_in_days = var.kms_deletion_window_in_days
  additional_tags             = local.sample_tags
}
