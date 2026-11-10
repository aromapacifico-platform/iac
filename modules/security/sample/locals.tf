locals {
  client      = "fnc"
  project     = "aromapacifico"
  environment = var.environment

  name_prefix = "${local.client}-${local.project}-${local.environment}"

  sample_tags = {
    Sample = "True"
  }
}
