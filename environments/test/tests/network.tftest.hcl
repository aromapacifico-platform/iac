mock_provider "aws" {}
variables {
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
    condition     = alltrue([for cidr in values(module.network.subnet_cidrs) : startswith(cidr, "10.60.")])
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
