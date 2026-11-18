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
run "environment_network_contract" {
  command = plan
  assert {
    condition     = length(module.network.subnet_cidrs) == 14 && module.network.transit_gateway_attachment_id == null
    error_message = "All environments must integrate fourteen subnets and keep real connectivity disabled by default."
  }
  assert {
    condition     = alltrue([for cidr in values(module.network.subnet_cidrs) : startswith(cidr, "10.50.")])
    error_message = "The root must use its approved environment CIDR."
  }
}
run "reject_unscoped_endpoint_grants" {
  command = plan
  variables {
    endpoint_access = {
      s3       = { principal_arns = ["*"], actions = ["s3:*"], resource_arns = ["*"] }
      dynamodb = { principal_arns = ["*"], actions = ["dynamodb:*"], resource_arns = ["*"] }
    }
  }
  expect_failures = [var.endpoint_access]
}

run "reject_question_mark_wildcards" {
  command = plan
  variables {
    endpoint_access = {
      s3       = { principal_arns = ["arn:aws:iam::111122223333:role/fixture"], actions = ["s3:GetObjec?"], resource_arns = ["arn:aws:s3:::fixture-only/*"] }
      dynamodb = { principal_arns = ["arn:aws:iam::111122223333:role/fixture"], actions = ["dynamodb:PutItem"], resource_arns = ["arn:aws:dynamodb:us-east-1:111122223333:table/fixture-?"] }
    }
  }
  expect_failures = [var.endpoint_access]
}

run "reject_all_dynamodb_tables" {
  command = plan
  variables {
    endpoint_access = {
      s3       = { principal_arns = ["arn:aws:iam::111122223333:role/fixture"], actions = ["s3:GetObject"], resource_arns = ["arn:aws:s3:::fixture-only/*"] }
      dynamodb = { principal_arns = ["arn:aws:iam::111122223333:role/fixture"], actions = ["dynamodb:PutItem"], resource_arns = ["arn:aws:dynamodb:us-east-1:111122223333:table/*"] }
    }
  }
  expect_failures = [var.endpoint_access]
}

run "gateway_endpoint_policies_authorize_environment_modules" {
  command = plan

  assert {
    condition = contains(
      flatten([
        for stmt in jsondecode(local.gateway_endpoint_policies["s3"]).Statement :
        stmt.Sid == "FocusFunctionS3Access" ? stmt.Principal.AWS : []
      ]),
      "arn:aws:iam::111122223333:role/fnc-aromapacifico-dev-role-focus-func"
      ) && contains(
      flatten([
        for stmt in jsondecode(local.gateway_endpoint_policies["s3"]).Statement :
        stmt.Sid == "FocusFunctionS3Access" ? stmt.Resource : []
      ]),
      "arn:aws:s3:::fnc-aromapacifico-dev-s3-focus-conf/*"
    )
    error_message = "S3 Gateway Endpoint policy must authorize role-focus-func on the environment focus confirmation bucket."
  }

  assert {
    condition = length(setintersection(
      toset(flatten([
        for stmt in jsondecode(local.gateway_endpoint_policies["dynamodb"]).Statement : stmt.Principal.AWS
      ])),
      toset([
        "arn:aws:iam::111122223333:role/fnc-aromapacifico-dev-role-ingest",
        "arn:aws:iam::111122223333:role/fnc-aromapacifico-dev-role-focus-func",
        "arn:aws:iam::111122223333:role/fnc-aromapacifico-dev-role-delivery"
      ])
      )) == 3 && length(setintersection(
      toset(flatten([
        for stmt in jsondecode(local.gateway_endpoint_policies["dynamodb"]).Statement : stmt.Resource
      ])),
      toset([
        "arn:aws:dynamodb:us-east-1:111122223333:table/fnc-aromapacifico-dev-dynamo-telemetry",
        "arn:aws:dynamodb:us-east-1:111122223333:table/fnc-aromapacifico-dev-dynamo-thresholds",
        "arn:aws:dynamodb:us-east-1:111122223333:table/fnc-aromapacifico-dev-dynamo-expedientes",
        "arn:aws:dynamodb:us-east-1:111122223333:table/fnc-aromapacifico-dev-dynamo-sacos"
      ])
    )) == 4
    error_message = "DynamoDB Gateway Endpoint policy must authorize ingest, focus_function and delivery roles over all four environment tables."
  }

  assert {
    condition = alltrue([
      for svc in ["s3", "dynamodb"] : alltrue([
        for stmt in jsondecode(local.gateway_endpoint_policies[svc]).Statement :
        !contains(stmt.Principal.AWS, "*") &&
        alltrue([for act in stmt.Action : !can(regex("[*?]", act))])
      ])
    ])
    error_message = "Gateway Endpoint policies must never use wildcard principals or actions."
  }
}
