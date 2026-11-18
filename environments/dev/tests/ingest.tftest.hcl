mock_provider "aws" {
  override_during = plan
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
  farm_certificate_csr = "-----BEGIN CERTIFICATE REQUEST-----\nQUJD\n-----END CERTIFICATE REQUEST-----"
  endpoint_access = {
    s3 = {
      principal_arns = ["arn:aws:iam::111122223333:role/fixture"]
      actions        = ["s3:GetObject"]
      resource_arns  = ["arn:aws:s3:::fixture-only/*"]
    }
    dynamodb = {
      principal_arns = ["arn:aws:iam::111122223333:role/fixture"]
      actions        = ["dynamodb:PutItem"]
      resource_arns  = ["arn:aws:dynamodb:us-east-1:111122223333:table/fixture-only"]
    }
  }
}

run "single_farm_and_security_names" {
  command = plan
  assert {
    condition     = module.farm.thing_name == "fnc-aromapacifico-dev-thing-cau-f001" && module.ingest.tables.telemetry.name == "fnc-aromapacifico-dev-dynamo-telemetry"
    error_message = "One farm and the telemetry table must use the security naming contract."
  }
  assert {
    condition     = module.ingest.tables.thresholds.name == "fnc-aromapacifico-dev-dynamo-thresholds" && module.ingest.mqtt_topics.cultivo == "$aws/rules/fnc_aromapacifico_dev_telemetry/aromapacifico/fincas/CAU-F001/telemetria/cultivo"
    error_message = "Threshold storage and the farm's physical MQTT topic must be wired."
  }
}
run "parameterized_farm" {
  command = plan
  variables { farm_id = "HUI-F201" }
  assert {
    condition     = module.farm.thing_name == "fnc-aromapacifico-dev-thing-hui-f201" && strcontains(module.ingest.mqtt_topics.secado, "/HUI-F201/")
    error_message = "Changing the farm input must change both identity and authorized topics."
  }
}
