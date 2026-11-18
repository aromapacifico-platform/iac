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
  mock_resource "aws_security_group" {
    defaults = { id = "sg-0123456789abcdef0" }
  }
  mock_resource "aws_network_acl" {
    defaults = { id = "acl-0123456789abcdef0" }
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
    defaults = {
      arn    = "arn:aws:kms:us-east-1:111122223333:key/11111111-2222-3333-4444-555555555555"
      key_id = "11111111-2222-3333-4444-555555555555"
    }
  }
}

variables {
  client                   = "fnc"
  project                  = "aromapacifico"
  environment              = "dev"
  name_prefix              = "fnc-aromapacifico-dev"
  vpc_id                   = "vpc-12345678"
  private_subnet_ids       = ["subnet-0123456789abcdef0"]
  public_subnet_ids        = ["subnet-0123456789abcdef1"]
  authorized_private_cidrs = ["10.50.0.0/16"]
  visitor_cidr             = "10.41.5.0/24"
  log_authorized_cidr      = "10.41.3.0/24"
  drone_backup_cidrs       = ["10.41.20.0/24"]
  admin_cidr               = "10.41.1.0/24"
  dns_cidr                 = "10.41.10.0/24"
  app_cidr                 = "10.50.10.0/24"
  ingest_rule_name         = "fnc_aromapacifico_dev_telemetry"
  focus_function_name      = "fnc-aromapacifico-dev-fn-focus-conf"
}

run "kms_rotation_and_domain_keys" {
  command = plan

  assert {
    condition     = toset(keys(aws_kms_key.this)) == toset(["data", "objects", "logs"]) && alltrue([for k, v in aws_kms_key.this : v.enable_key_rotation == true && v.deletion_window_in_days == 30])
    error_message = "All three domain KMS keys must enable annual rotation with 30-day deletion window."
  }

  assert {
    condition     = aws_kms_alias.this["data"].name == "alias/fnc-aromapacifico-dev-kms-data" && aws_kms_alias.this["objects"].name == "alias/fnc-aromapacifico-dev-kms-objects" && aws_kms_alias.this["logs"].name == "alias/fnc-aromapacifico-dev-kms-logs"
    error_message = "KMS aliases must follow the root-built name_prefix convention."
  }
}

run "iam_least_privilege_zero_wildcards" {
  command = plan

  assert {
    condition     = alltrue(flatten([for stmt in jsondecode(aws_iam_role_policy.delivery.policy).Statement : [for act in stmt.Action : !strcontains(act, "*") if !startswith(act, "kms:GenerateDataKey")]]))
    error_message = "Delivery role actions must avoid wildcards on DynamoDB and CloudWatch Logs."
  }

  assert {
    condition     = alltrue(flatten([for stmt in jsondecode(aws_iam_role_policy.flow_logs.policy).Statement : [for act in stmt.Action : !strcontains(act, "*")]]))
    error_message = "VPC Flow Logs role must enumerate explicit CloudWatch Logs actions without wildcards."
  }

  assert {
    condition     = [for stmt in jsondecode(aws_iam_role_policy.focus_function.policy).Statement : stmt.Resource if stmt.Sid == "BedrockLeafDiagnosis"][0] == "arn:aws:bedrock:us-east-1::foundation-model/amazon.nova-lite-v1:0"
    error_message = "Focus function role must scope bedrock:InvokeModel to the configured foundation model."
  }
}

run "permanent_firewall_catalog_and_c19_retired" {
  command = plan

  assert {
    condition     = length(output.security_group_ids) == 14 && !contains(keys(output.rule_catalog), "sg_egress[\"C19\"]") && contains(keys(output.rule_catalog), "sg_ingress[\"C01\"]") && contains(keys(output.rule_catalog), "sg_egress[\"C20\"]")
    error_message = "Security module must provision the 14 permanent Security Groups with C19 retired per FinOps decision #31."
  }

  assert {
    condition     = [for rule in aws_network_acl.private.ingress : rule if rule.rule_no == 10 && rule.action == "deny" && rule.cidr_block == var.visitor_cidr] != []
    error_message = "Private NACL must explicitly deny visitor_cidr at rule_no 10 (N01)."
  }

  assert {
    condition     = [for rule in aws_network_acl.public.ingress : rule if rule.rule_no == 100 && rule.action == "allow" && rule.from_port == 443 && rule.cidr_block == "0.0.0.0/0"] != []
    error_message = "Public NACL must allow HTTPS 443 ingress (N12)."
  }
}

run "reject_invalid_name_prefix" {
  command = plan
  variables { name_prefix = "INVALID_PREFIX" }
  expect_failures = [var.name_prefix]
}

run "reject_invalid_vpc_id" {
  command = plan
  variables { vpc_id = "not-a-vpc" }
  expect_failures = [var.vpc_id]
}
