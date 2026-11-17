locals {
  client      = "fnc"
  project     = "aromapacifico"
  environment = var.environment

  name_prefix         = "${local.client}-${local.project}-${local.environment}"
  ingest_rule_name    = replace("${local.name_prefix}-telemetry", "-", "_")
  focus_function_name = "${local.name_prefix}-fn-focus-conf"

  sample_tags = merge(
    var.additional_tags,
    {
      Fixture = "modules/security/sample"
    }
  )
}
