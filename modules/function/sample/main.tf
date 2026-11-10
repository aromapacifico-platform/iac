# ==============================================================================
# Sample Module Invocation (PC-IAC-013, PC-IAC-026)
# ==============================================================================

module "function" {
  # Grupo A: Source
  source = "../"

  # Grupo B: Providers (PC-IAC-005)
  providers = {
    aws.project = aws.principal
  }

  # Grupo C: Gobernanza
  client      = var.client
  project     = var.project
  environment = var.environment

  # Grupo D: Transversales
  name_prefix         = local.name_prefix
  kms_key_objects_arn = var.mock_kms_key_objects_arn
  kms_key_data_arn    = var.mock_kms_key_data_arn

  # Grupo E: Variables Específicas
  expedientes_table_name = var.expedientes_table_name
  additional_tags        = local.common_tags
}
