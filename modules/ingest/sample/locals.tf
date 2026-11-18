locals {
  default_tags = {
    FincaID  = "GLOBAL", DronID = "NO-APLICA", AcopioID = "MULTICENTRO", ViajeID = "NO-APLICA",
    Ambiente = "desarrollo", Propietario = "devops-fnc", Proyecto = "AromaPacifico"
  }
  name_prefix = "${var.client}-${var.project}-${var.environment}"
  thing_name  = "${local.name_prefix}-thing-${lower(var.farm_id)}"
  resource_names = {
    telemetry  = "${local.name_prefix}-dynamo-telemetry"
    thresholds = "${local.name_prefix}-dynamo-thresholds"
    queue      = "${local.name_prefix}-sqs-telemetry"
    dlq        = "${local.name_prefix}-sqs-telemetry-dlq"
    rule       = replace("${local.name_prefix}-telemetry", "-", "_")
    policy     = "${local.name_prefix}-iot-${lower(var.farm_id)}"
  }
}
