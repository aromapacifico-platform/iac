module "ingest" {
  source          = "../"
  providers       = { aws.project = aws.principal }
  aws_account_id  = var.aws_account_id
  aws_region      = var.aws_region
  kms_key_arn     = var.kms_key_arn
  ingest_role_arn = var.ingest_role_arn
  farm_id         = var.farm_id
  additional_tags = var.additional_tags
  thing_name      = local.thing_name
  resource_names  = local.resource_names
}
