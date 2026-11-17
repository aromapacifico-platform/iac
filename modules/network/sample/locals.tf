locals {
  ambiente = {
    dev  = "desarrollo"
    test = "pruebas"
    prod = "produccion"
  }

  name_prefix = "${var.client}-${var.project}-${var.environment}"

  default_tags = {
    FincaID     = "GLOBAL"
    DronID      = "NO-APLICA"
    AcopioID    = "MULTICENTRO"
    ViajeID     = "NO-APLICA"
    Ambiente    = local.ambiente[var.environment]
    Propietario = "devops-fnc"
    Proyecto    = "AromaPacifico"
  }

  gateway_endpoint_policies = {
    s3 = jsonencode({
      Version = "2012-10-17"
      Statement = [{
        Sid       = "ScopedSampleS3Access"
        Effect    = "Allow"
        Principal = { AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root" }
        Action    = ["s3:GetObject", "s3:PutObject"]
        Resource  = ["arn:aws:s3:::${local.name_prefix}-sample/*"]
      }]
    })
    dynamodb = jsonencode({
      Version = "2012-10-17"
      Statement = [{
        Sid       = "ScopedSampleDynamoAccess"
        Effect    = "Allow"
        Principal = { AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root" }
        Action    = ["dynamodb:GetItem", "dynamodb:PutItem"]
        Resource  = ["arn:aws:dynamodb:${var.aws_region}:${data.aws_caller_identity.current.account_id}:table/${local.name_prefix}-dynamo-telemetry"]
      }]
    })
  }
}
