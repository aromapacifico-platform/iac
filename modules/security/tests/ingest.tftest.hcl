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

variables {
  client           = "fnc"
  project          = "aromapacifico"
  environment      = "dev"
  vpc_id           = "vpc-12345678"
  ingest_rule_name = "fnc_aromapacifico_dev_telemetry"
}
run "ingest_role_contract" {
  command = plan
  assert {
    condition     = jsondecode(aws_iam_role.ingest.assume_role_policy).Statement[0].Condition.StringEquals["aws:SourceAccount"] == "111122223333" && jsondecode(aws_iam_role.ingest.assume_role_policy).Statement[0].Condition.ArnEquals["aws:SourceArn"] == "arn:aws:iot:us-east-1:111122223333:rule/fnc_aromapacifico_dev_telemetry"
    error_message = "Only the exact account and IoT rule may assume the ingestion role."
  }
  assert {
    condition     = jsondecode(aws_iam_role_policy.ingest.policy).Statement[0].Resource == "arn:aws:dynamodb:us-east-1:111122223333:table/fnc-aromapacifico-dev-dynamo-telemetry" && jsondecode(aws_iam_role_policy.ingest.policy).Statement[1].Resource == "arn:aws:sqs:us-east-1:111122223333:fnc-aromapacifico-dev-sqs-telemetry"
    error_message = "Actual security permissions must match the workload resource names."
  }
  assert {
    condition     = toset(jsondecode(aws_iam_role_policy.ingest.policy).Statement[2].Action) == toset(["kms:Decrypt", "kms:GenerateDataKey", "kms:DescribeKey"]) && toset(jsondecode(aws_iam_role_policy.ingest.policy).Statement[2].Condition.StringEquals["kms:ViaService"]) == toset(["sqs.us-east-1.amazonaws.com", "dynamodb.us-east-1.amazonaws.com"])
    error_message = "SQS producers and DynamoDB require exact KMS permissions through their services."
  }
  assert {
    condition     = alltrue(flatten([for statement in jsondecode(aws_iam_role_policy.ingest.policy).Statement : [for action in statement.Action : !strcontains(action, "*")]]))
    error_message = "Ingestion data actions must have no wildcards."
  }
}
