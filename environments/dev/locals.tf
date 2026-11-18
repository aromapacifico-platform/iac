locals {
  ambiente = {
    dev  = "desarrollo"
    test = "pruebas"
    prod = "produccion"
  }

  name_prefix = "aromapacifico-${var.environment}"

  # Mandatory tags of the landing zone. Modules override FincaID, DronID,
  # AcopioID and ViajeID on the resources that belong to one of them.
  default_tags = {
    FincaID     = "GLOBAL"
    DronID      = "NO-APLICA"
    AcopioID    = "MULTICENTRO"
    ViajeID     = "NO-APLICA"
    Ambiente    = local.ambiente[var.environment]
    Propietario = var.owner
    Proyecto    = "AromaPacifico"
  }

  gateway_endpoint_policies = {
    for service, access in var.endpoint_access : service => jsonencode({
      Version = "2012-10-17"
      Statement = [{
        Sid       = "ScopedEnvironmentAccess"
        Effect    = "Allow"
        Principal = { AWS = access.principal_arns }
        Action    = access.actions
        Resource  = access.resource_arns
      }]
    })
  }

  security_prefix = "${var.client}-${var.project}-${var.environment}"
  thing_name      = "${local.security_prefix}-thing-${lower(var.farm_id)}"
  ingest_names = {
    telemetry  = "${local.security_prefix}-dynamo-telemetry"
    thresholds = "${local.security_prefix}-dynamo-thresholds"
    queue      = "${local.security_prefix}-sqs-telemetry"
    dlq        = "${local.security_prefix}-sqs-telemetry-dlq"
    rule       = replace("${local.security_prefix}-telemetry", "-", "_")
    policy     = "${local.security_prefix}-iot-${lower(var.farm_id)}"
  }
}
