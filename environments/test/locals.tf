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

  account_id             = data.aws_caller_identity.current.account_id
  security_prefix        = "${var.client}-${var.project}-${var.environment}"
  thing_name             = "${local.security_prefix}-thing-${lower(var.farm_id)}"
  focus_bucket_name      = "${local.security_prefix}-s3-focus-conf"
  expedientes_table_name = "${local.security_prefix}-dynamo-expedientes"
  sacos_table_name       = "${local.security_prefix}-dynamo-sacos"
  focus_function_name    = "${local.security_prefix}-fn-focus-conf"
  ingest_names = {
    telemetry  = "${local.security_prefix}-dynamo-telemetry"
    thresholds = "${local.security_prefix}-dynamo-thresholds"
    queue      = "${local.security_prefix}-sqs-telemetry"
    dlq        = "${local.security_prefix}-sqs-telemetry-dlq"
    rule       = replace("${local.security_prefix}-telemetry", "-", "_")
    policy     = "${local.security_prefix}-iot-${lower(var.farm_id)}"
  }
  role_arns = {
    ingest         = "arn:aws:iam::${local.account_id}:role/${local.security_prefix}-role-ingest"
    focus_function = "arn:aws:iam::${local.account_id}:role/${local.security_prefix}-role-focus-func"
    delivery       = "arn:aws:iam::${local.account_id}:role/${local.security_prefix}-role-delivery"
  }

  gateway_endpoint_statements = {
    s3 = [
      {
        Sid       = "ScopedEnvironmentAccess"
        Effect    = "Allow"
        Principal = { AWS = tolist(var.endpoint_access["s3"].principal_arns) }
        Action    = tolist(var.endpoint_access["s3"].actions)
        Resource  = tolist(var.endpoint_access["s3"].resource_arns)
      },
      {
        Sid       = "FocusFunctionS3Access"
        Effect    = "Allow"
        Principal = { AWS = [local.role_arns.focus_function] }
        Action    = ["s3:GetObject", "s3:GetObjectVersion", "s3:ListBucket"]
        Resource = [
          "arn:aws:s3:::${local.focus_bucket_name}",
          "arn:aws:s3:::${local.focus_bucket_name}/*"
        ]
      }
    ]
    dynamodb = [
      {
        Sid       = "ScopedEnvironmentAccess"
        Effect    = "Allow"
        Principal = { AWS = tolist(var.endpoint_access["dynamodb"].principal_arns) }
        Action    = tolist(var.endpoint_access["dynamodb"].actions)
        Resource  = tolist(var.endpoint_access["dynamodb"].resource_arns)
      },
      {
        Sid       = "IngestDynamoAccess"
        Effect    = "Allow"
        Principal = { AWS = [local.role_arns.ingest] }
        Action    = ["dynamodb:PutItem", "dynamodb:GetItem", "dynamodb:Query"]
        Resource = [
          "arn:aws:dynamodb:${var.aws_region}:${local.account_id}:table/${local.ingest_names.telemetry}",
          "arn:aws:dynamodb:${var.aws_region}:${local.account_id}:table/${local.ingest_names.thresholds}"
        ]
      },
      {
        Sid       = "FocusFunctionDynamoAccess"
        Effect    = "Allow"
        Principal = { AWS = [local.role_arns.focus_function] }
        Action    = ["dynamodb:PutItem", "dynamodb:UpdateItem", "dynamodb:GetItem"]
        Resource  = ["arn:aws:dynamodb:${var.aws_region}:${local.account_id}:table/${local.expedientes_table_name}"]
      },
      {
        Sid       = "DeliveryDynamoAccess"
        Effect    = "Allow"
        Principal = { AWS = [local.role_arns.delivery] }
        Action    = ["dynamodb:PutItem", "dynamodb:UpdateItem", "dynamodb:GetItem"]
        Resource  = ["arn:aws:dynamodb:${var.aws_region}:${local.account_id}:table/${local.sacos_table_name}"]
      }
    ]
  }

  gateway_endpoint_policies = {
    for service, statements in local.gateway_endpoint_statements : service => jsonencode({
      Version   = "2012-10-17"
      Statement = statements
    })
  }
}
