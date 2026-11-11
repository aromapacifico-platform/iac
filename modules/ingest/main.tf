resource "aws_dynamodb_table" "this" {
  provider                    = aws.project
  for_each                    = local.tables
  name                        = each.value.name
  billing_mode                = "PAY_PER_REQUEST"
  hash_key                    = "pk"
  range_key                   = "sk"
  deletion_protection_enabled = true
  stream_enabled              = true
  stream_view_type            = "NEW_AND_OLD_IMAGES"

  attribute {
    name = "pk"
    type = "S"
  }
  attribute {
    name = "sk"
    type = "S"
  }
  dynamic "attribute" {
    for_each = each.key == "telemetry" ? { history_pk = "S", history_sk = "S" } : {}
    content {
      name = attribute.key
      type = attribute.value
    }
  }
  dynamic "global_secondary_index" {
    for_each = each.key == "telemetry" ? { history = true } : {}
    content {
      name            = global_secondary_index.key
      projection_type = "ALL"
      key_schema {
        attribute_name = "history_pk"
        key_type       = "HASH"
      }
      key_schema {
        attribute_name = "history_sk"
        key_type       = "RANGE"
      }
    }
  }
  server_side_encryption {
    enabled     = true
    kms_key_arn = var.kms_key_arn
  }
  point_in_time_recovery { enabled = true }
  # No TTL: retain history until a verified archive can cover five calendar years.
  tags = merge(local.tags, { Name = each.value.name })
  lifecycle { prevent_destroy = true }
}

resource "aws_sqs_queue" "dead_letter" {
  provider                  = aws.project
  name                      = var.resource_names.dlq
  kms_master_key_id         = var.kms_key_arn
  message_retention_seconds = 1209600
  tags                      = merge(local.tags, { Name = var.resource_names.dlq })
}

resource "aws_sqs_queue" "this" {
  provider                   = aws.project
  name                       = var.resource_names.queue
  kms_master_key_id          = var.kms_key_arn
  message_retention_seconds  = 1209600
  visibility_timeout_seconds = 180
  redrive_policy             = jsonencode({ deadLetterTargetArn = aws_sqs_queue.dead_letter.arn, maxReceiveCount = 5 })
  tags                       = merge(local.tags, { Name = var.resource_names.queue })
}

resource "aws_sqs_queue_redrive_allow_policy" "this" {
  provider             = aws.project
  queue_url            = aws_sqs_queue.dead_letter.id
  redrive_allow_policy = jsonencode({ redrivePermission = "byQueue", sourceQueueArns = [aws_sqs_queue.this.arn] })
}

resource "aws_iot_policy" "this" {
  provider = aws.project
  name     = var.resource_names.policy
  policy   = local.device_policy
  tags     = merge(var.additional_tags, { Name = var.resource_names.policy, FincaID = var.farm_id })
}

resource "aws_iot_topic_rule" "this" {
  provider    = aws.project
  name        = var.resource_names.rule
  description = "Farm-scoped telemetry landing store; no business ACK or alert evaluation."
  enabled     = true
  sql         = local.rule_sql
  sql_version = "2016-03-23"
  dynamodbv2 {
    role_arn = var.ingest_role_arn
    put_item { table_name = aws_dynamodb_table.this["telemetry"].name }
  }
  error_action {
    sqs {
      role_arn   = var.ingest_role_arn
      queue_url  = aws_sqs_queue.this.url
      use_base64 = false
    }
  }
  tags = merge(local.tags, { Name = var.resource_names.rule })
}
