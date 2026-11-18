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
  farm_id     = "CAU-F001"
  thing_name  = "fnc-aromapacifico-dev-thing-cau-f001"
  policy_name = "fnc-aromapacifico-dev-iot-cau-f001"
  # Deliberately synthetic public CSR accepted only by a mocked provider.
  certificate_csr = "-----BEGIN CERTIFICATE REQUEST-----\nQUJD\n-----END CERTIFICATE REQUEST-----"
}

run "certificate_active" {
  command = plan
  variables { certificate_active = true }
  assert {
    condition     = issensitive(output.certificate_pem)
    error_message = "The public certificate output must preserve its sensitive marking."
  }
  assert {
    condition     = aws_iot_certificate.this.active && aws_iot_certificate.this.csr == var.certificate_csr
    error_message = "Activation must use the caller's CSR without generating a private key."
  }
  assert {
    condition     = aws_iot_thing.this.attributes.FincaID == var.farm_id && aws_iot_thing.this.name == var.thing_name && aws_iot_policy_attachment.this.policy == var.policy_name
    error_message = "The single thing and policy must belong to the supplied farm."
  }
}
run "certificate_deactivated" {
  command = plan
  variables { certificate_active = false }
  assert {
    condition     = !aws_iot_certificate.this.active && aws_iot_thing_principal_attachment.this.thing == var.thing_name
    error_message = "Offboarding must set certificate status inactive, retaining the identity."
  }
}
run "reject_empty_csr" {
  command = plan
  variables { certificate_csr = "" }
  expect_failures = [var.certificate_csr]
}
run "reject_private_key_as_csr" {
  command = plan
  variables { certificate_csr = "PRIVATE KEY INPUT IS NOT A CSR" }
  expect_failures = [var.certificate_csr]
}
run "reject_null_csr" {
  command = plan
  variables { certificate_csr = null }
  expect_failures = [var.certificate_csr]
}
run "reject_invalid_farm_id" {
  command = plan
  variables { farm_id = "CAU-F001/+" }
  expect_failures = [var.farm_id]
}
