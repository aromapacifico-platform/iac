mock_provider "aws" {
  override_during = plan
  alias           = "project"
  mock_resource "aws_vpc" {
    defaults = { id = "vpc-0123456789abcdef0" }
  }
  mock_resource "aws_subnet" {
    defaults = { id = "subnet-0123456789abcdef0" }
  }
  mock_resource "aws_iam_role" {
    defaults = { arn = "arn:aws:iam::111122223333:role/mock-security-role" }
  }
  mock_resource "aws_iot_certificate" {
    defaults = { arn = "arn:aws:iot:us-east-1:111122223333:cert/1111111111111111111111111111111111111111111111111111111111111111" }
  }

  mock_data "aws_caller_identity" {
    defaults = { account_id = "111122223333", arn = "arn:aws:iam::111122223333:root", user_id = "mock" }
  }
  mock_data "aws_region" {
    defaults = { name = "us-east-1", region = "us-east-1" }
  }
  mock_data "aws_iam_policy_document" {
    defaults = { json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}" }
  }
  mock_resource "aws_kms_key" {
    defaults = { arn = "arn:aws:kms:us-east-1:111122223333:key/11111111-2222-3333-4444-555555555555" }
  }
}

# Supply only computed queue identities during plan. Policies still come from
# the module's jsonencode expressions and retain their real queue references.
override_resource {
  target          = aws_sqs_queue.dead_letter
  override_during = plan
  values = {
    arn = "arn:aws:sqs:us-east-1:111122223333:fnc-aromapacifico-dev-sqs-telemetry-dlq"
    id  = "https://sqs.us-east-1.amazonaws.com/111122223333/fnc-aromapacifico-dev-sqs-telemetry-dlq"
    url = "https://sqs.us-east-1.amazonaws.com/111122223333/fnc-aromapacifico-dev-sqs-telemetry-dlq"
  }
}

override_resource {
  target          = aws_sqs_queue.this
  override_during = plan
  values = {
    arn = "arn:aws:sqs:us-east-1:111122223333:fnc-aromapacifico-dev-sqs-telemetry"
    id  = "https://sqs.us-east-1.amazonaws.com/111122223333/fnc-aromapacifico-dev-sqs-telemetry"
    url = "https://sqs.us-east-1.amazonaws.com/111122223333/fnc-aromapacifico-dev-sqs-telemetry"
  }
}

variables {
  aws_account_id  = "111122223333"
  aws_region      = "us-east-1"
  kms_key_arn     = "arn:aws:kms:us-east-1:111122223333:key/11111111-2222-3333-4444-555555555555"
  ingest_role_arn = "arn:aws:iam::111122223333:role/fnc-aromapacifico-dev-role-ingest"
  farm_id         = "CAU-F001"
  thing_name      = "fnc-aromapacifico-dev-thing-cau-f001"
  resource_names = {
    telemetry  = "fnc-aromapacifico-dev-dynamo-telemetry"
    thresholds = "fnc-aromapacifico-dev-dynamo-thresholds"
    queue      = "fnc-aromapacifico-dev-sqs-telemetry"
    dlq        = "fnc-aromapacifico-dev-sqs-telemetry-dlq"
    rule       = "fnc_aromapacifico_dev_telemetry"
    policy     = "fnc-aromapacifico-dev-iot-cau-f001"
  }
}

run "encrypted_reception_and_retention" {
  command = plan
  assert {
    condition     = alltrue([for table in aws_dynamodb_table.this : table.server_side_encryption[0].enabled && table.server_side_encryption[0].kms_key_arn == var.kms_key_arn && table.point_in_time_recovery[0].enabled && table.deletion_protection_enabled])
    error_message = "Both tables must use the security data key, PITR and deletion protection."
  }
  assert {
    condition     = alltrue([for table in aws_dynamodb_table.this : alltrue([for ttl in table.ttl : !ttl.enabled])])
    error_message = "No automatic expiry is allowed before verified five-year archival."
  }
  assert {
    condition     = aws_sqs_queue.this.kms_master_key_id == var.kms_key_arn && aws_sqs_queue.dead_letter.kms_master_key_id == var.kms_key_arn && aws_sqs_queue.this.message_retention_seconds == 1209600 && jsondecode(aws_sqs_queue.this.redrive_policy).maxReceiveCount == 5
    error_message = "Reception failures and their DLQ need KMS, bounded retries and fourteen-day retention."
  }
  assert {
    condition     = aws_sqs_queue.this.arn != aws_sqs_queue.dead_letter.arn && jsondecode(aws_sqs_queue.this.redrive_policy).deadLetterTargetArn == aws_sqs_queue.dead_letter.arn && jsondecode(aws_sqs_queue_redrive_allow_policy.this.redrive_allow_policy).sourceQueueArns == [aws_sqs_queue.this.arn] && jsondecode(aws_sqs_queue_redrive_allow_policy.this.redrive_allow_policy).redrivePermission == "byQueue"
    error_message = "Redrive policies must link the actual reception queue and its distinct DLQ."
  }
  assert {
    condition     = one(aws_iot_topic_rule.this.dynamodbv2).put_item[0].table_name == var.resource_names.telemetry && one(aws_iot_topic_rule.this.dynamodbv2).role_arn == var.ingest_role_arn && aws_iot_topic_rule.this.error_action[0].sqs[0].role_arn == var.ingest_role_arn
    error_message = "Both rule actions must consume the security-owned role and the real table name."
  }
}
run "farm_isolation" {
  command = plan
  assert {
    condition     = jsondecode(aws_iot_policy.this.policy).Statement[0].Resource == ["arn:aws:iot:us-east-1:111122223333:client/fnc-aromapacifico-dev-thing-cau-f001"] && jsondecode(aws_iot_policy.this.policy).Statement[0].Condition.Bool["iot:Connection.Thing.IsAttached"] == "true" && jsondecode(aws_iot_policy.this.policy).Statement[0].Condition.StringEquals["iot:ClientId"] == var.thing_name
    error_message = "Connect requires the exact ClientId and an attached certificate."
  }
  assert {
    condition = toset(jsondecode(aws_iot_policy.this.policy).Statement[1].Resource) == toset([
      "arn:aws:iot:us-east-1:111122223333:topic/$aws/rules/fnc_aromapacifico_dev_telemetry/aromapacifico/fincas/CAU-F001/telemetria/cultivo",
      "arn:aws:iot:us-east-1:111122223333:topic/$aws/rules/fnc_aromapacifico_dev_telemetry/aromapacifico/fincas/CAU-F001/telemetria/secado"
    ])
    error_message = "Publish must allow only two physical Basic Ingest topics for this farm."
  }
  assert {
    condition     = alltrue(flatten([for statement in jsondecode(aws_iot_policy.this.policy).Statement : [for resource in statement.Resource : !can(regex("[*?]", resource))]])) && jsondecode(aws_iot_policy.this.policy).Statement[2].Resource == ["arn:aws:iot:us-east-1:111122223333:topicfilter/aromapacifico/fincas/CAU-F001/config"]
    error_message = "No wildcard resource or another farm's config is authorized."
  }
  assert {
    condition     = strcontains(aws_iot_topic_rule.this.sql, "topic(3) AS farm_id") && !strcontains(aws_iot_topic_rule.this.sql, "SELECT *") && !strcontains(aws_iot_topic_rule.this.sql, "expires_at") && strcontains(aws_iot_topic_rule.this.sql, "traceid()")
    error_message = "Trusted identity and keys come from the topic; the payload cannot inject TTL or identity."
  }
}
run "reject_mqtt_wildcard_in_farm" {
  command = plan
  variables { farm_id = "CAU-F001/#" }
  expect_failures = [var.farm_id]
}
run "reject_wildcard_client" {
  command = plan
  variables { thing_name = "*" }
  expect_failures = [var.thing_name]
}
run "reject_unscoped_role" {
  command = plan
  variables { ingest_role_arn = "arn:aws:iam::111122223333:role/*" }
  expect_failures = [var.ingest_role_arn]
}
