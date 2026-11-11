locals {
  tags           = merge(var.additional_tags, { Component = "Ingest", ManagedBy = "Terraform", FincaID = "GLOBAL" })
  iot_arn_prefix = "arn:aws:iot:${var.aws_region}:${var.aws_account_id}"
  mqtt_topics = {
    cultivo = "$aws/rules/${var.resource_names.rule}/aromapacifico/fincas/${var.farm_id}/telemetria/cultivo"
    secado  = "$aws/rules/${var.resource_names.rule}/aromapacifico/fincas/${var.farm_id}/telemetria/secado"
  }
  config_topic = "aromapacifico/fincas/${var.farm_id}/config"
  tables = {
    telemetry  = { name = var.resource_names.telemetry }
    thresholds = { name = var.resource_names.thresholds }
  }
  # Select fields explicitly; a payload cannot override identity, keys or TTL.
  # This landing record is not an evaluated business transaction or an ACK.
  rule_sql = <<-SQL
    SELECT concat('DEVICE#', topic(3)) AS pk,
           concat('EVENT#', event_id, '#RECEIPT#', traceid()) AS sk,
           concat('FARM#', topic(3), '#KIND#', topic(5), '#DAY#', substring(occurred_at, 0, 10)) AS history_pk,
           concat(occurred_at, '#', event_id, '#', traceid()) AS history_sk,
           topic(3) AS farm_id, topic(3) AS device_id, topic(5) AS kind,
           clientid() AS mqtt_client_id, principal() AS mqtt_principal,
           timestamp() AS edge_received_at_ms, traceid() AS ingest_receipt_id,
           event_id, schema_version, sequence, occurred_at,
           calibration_version, measurements, quality
    FROM 'aromapacifico/fincas/${var.farm_id}/telemetria/+'
    WHERE (topic(5) = 'cultivo' OR topic(5) = 'secado')
      AND clientid() = '${var.thing_name}'
      AND isUndefined(event_id) = false AND isUndefined(occurred_at) = false
  SQL
  device_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "ConnectOnlyAttachedFarm"
        Effect   = "Allow"
        Action   = ["iot:Connect"]
        Resource = ["${local.iot_arn_prefix}:client/${var.thing_name}"]
        Condition = {
          Bool         = { "iot:Connection.Thing.IsAttached" = "true" }
          StringEquals = { "iot:ClientId" = var.thing_name }
        }
      },
      {
        Sid      = "PublishOwnTelemetry"
        Effect   = "Allow"
        Action   = ["iot:Publish"]
        Resource = [for topic in values(local.mqtt_topics) : "${local.iot_arn_prefix}:topic/${topic}"]
      },
      {
        Sid      = "SubscribeOwnConfig"
        Effect   = "Allow"
        Action   = ["iot:Subscribe"]
        Resource = ["${local.iot_arn_prefix}:topicfilter/${local.config_topic}"]
      },
      {
        Sid      = "ReceiveOwnConfig"
        Effect   = "Allow"
        Action   = ["iot:Receive"]
        Resource = ["${local.iot_arn_prefix}:topic/${local.config_topic}"]
      }
    ]
  })
}
