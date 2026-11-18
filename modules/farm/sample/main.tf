module "farm" {
  source             = "../"
  providers          = { aws.project = aws.principal }
  farm_id            = var.farm_id
  certificate_csr    = var.certificate_csr
  certificate_active = var.certificate_active
  policy_name        = var.policy_name
  additional_tags    = var.additional_tags
  thing_name         = local.thing_name
}
