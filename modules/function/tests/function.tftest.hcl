mock_provider "aws" {
  override_during = plan
  alias           = "project"

  mock_data "aws_caller_identity" {
    defaults = { account_id = "111122223333", arn = "arn:aws:iam::111122223333:root", user_id = "mock" }
  }
  mock_data "aws_region" {
    defaults = { name = "us-east-1", region = "us-east-1" }
  }
  mock_data "aws_partition" {
    defaults = { partition = "aws" }
  }
  mock_resource "aws_s3_bucket" {
    defaults = {
      id  = "fnc-aromapacifico-dev-s3-focus-conf"
      arn = "arn:aws:s3:::fnc-aromapacifico-dev-s3-focus-conf"
    }
  }
  mock_resource "aws_sqs_queue" {
    defaults = {
      id  = "https://sqs.us-east-1.amazonaws.com/111122223333/fnc-aromapacifico-dev-sqs-focus-dlq"
      arn = "arn:aws:sqs:us-east-1:111122223333:fnc-aromapacifico-dev-sqs-focus-dlq"
      url = "https://sqs.us-east-1.amazonaws.com/111122223333:fnc-aromapacifico-dev-sqs-focus-dlq"
    }
  }
  mock_resource "aws_lambda_function" {
    defaults = {
      arn           = "arn:aws:lambda:us-east-1:111122223333:function:fnc-aromapacifico-dev-fn-focus-conf"
      function_name = "fnc-aromapacifico-dev-fn-focus-conf"
    }
  }
}

mock_provider "archive" {
  override_during = plan
}

variables {
  client                 = "fnc"
  project                = "aromapacifico"
  environment            = "dev"
  name_prefix            = "fnc-aromapacifico-dev"
  expedientes_table_name = "fnc-aromapacifico-dev-dynamo-expedientes"
  kms_key_objects_arn    = "arn:aws:kms:us-east-1:111122223333:key/11111111-2222-3333-4444-555555555555"
  kms_key_data_arn       = "arn:aws:kms:us-east-1:111122223333:key/22222222-2222-3333-4444-555555555555"
  kms_key_logs_arn       = "arn:aws:kms:us-east-1:111122223333:key/33333333-2222-3333-4444-555555555555"
  iam_role_arn           = "arn:aws:iam::111122223333:role/fnc-aromapacifico-dev-role-focus-func"
  subnet_ids             = ["subnet-0123456789abcdef0", "subnet-0123456789abcdef1"]
  security_group_ids     = ["sg-0123456789abcdef0"]
}

run "s3_hardening_and_tls_policy" {
  command = plan

  assert {
    condition     = aws_s3_bucket.this.bucket == "fnc-aromapacifico-dev-s3-focus-conf" && aws_s3_bucket.this.force_destroy == false
    error_message = "Focus confirmation S3 bucket must use the security naming contract and protect against forced destruction."
  }

  assert {
    condition     = aws_s3_bucket_public_access_block.this.block_public_acls && aws_s3_bucket_public_access_block.this.block_public_policy && aws_s3_bucket_public_access_block.this.ignore_public_acls && aws_s3_bucket_public_access_block.this.restrict_public_buckets
    error_message = "All four S3 Public Access Block flags must be enabled per PC-IAC-020."
  }

  assert {
    condition     = one(aws_s3_bucket_ownership_controls.this.rule).object_ownership == "BucketOwnerEnforced"
    error_message = "S3 bucket ownership controls must enforce BucketOwnerEnforced."
  }

  assert {
    condition     = one(one(aws_s3_bucket_server_side_encryption_configuration.this.rule).apply_server_side_encryption_by_default).sse_algorithm == "aws:kms" && one(one(aws_s3_bucket_server_side_encryption_configuration.this.rule).apply_server_side_encryption_by_default).kms_master_key_id == var.kms_key_objects_arn && one(aws_s3_bucket_server_side_encryption_configuration.this.rule).bucket_key_enabled
    error_message = "S3 confirmation bucket must enforce SSE-KMS with the objects CMK and bucket keys."
  }

  assert {
    condition     = [for s in jsondecode(aws_s3_bucket_policy.this.policy).Statement : s if s.Sid == "DenyInsecureTransport" && s.Effect == "Deny" && s.Condition.Bool["aws:SecureTransport"] == "false"] != []
    error_message = "S3 bucket policy must deny unencrypted HTTP transport (aws:SecureTransport = false)."
  }

  assert {
    condition     = [for s in jsondecode(aws_s3_bucket_policy.this.policy).Statement : s if s.Sid == "DenyOutdatedTls" && s.Effect == "Deny" && s.Condition.NumericLessThan["s3:TlsVersion"] == "1.2"] != []
    error_message = "S3 bucket policy must deny TLS versions below 1.2."
  }
}

run "lambda_resilience_dlq_and_vpc_contract" {
  command = plan

  assert {
    condition     = aws_lambda_function.this.function_name == "fnc-aromapacifico-dev-fn-focus-conf" && aws_cloudwatch_log_group.this.name == "/aws/lambda/fnc-aromapacifico-dev-fn-focus-conf" && aws_cloudwatch_log_group.this.kms_key_id == var.kms_key_logs_arn
    error_message = "Lambda and its KMS-encrypted CloudWatch Log Group must match the -fn-focus-conf naming contract."
  }

  assert {
    condition     = aws_sqs_queue.dlq.message_retention_seconds == 1209600 && aws_sqs_queue.dlq.kms_master_key_id == var.kms_key_data_arn
    error_message = "Focus DLQ must enforce 14-day retention and KMS encryption."
  }

  assert {
    condition     = aws_lambda_function_event_invoke_config.this.maximum_retry_attempts == 2 && one(aws_lambda_function.this.tracing_config).mode == "Active" && toset(one(aws_lambda_function.this.vpc_config).subnet_ids) == toset(var.subnet_ids) && toset(one(aws_lambda_function.this.vpc_config).security_group_ids) == toset(var.security_group_ids)
    error_message = "Lambda must run inside private subnets with Active tracing and max 2 retries to DLQ."
  }

  assert {
    condition     = one(aws_s3_bucket_notification.this.lambda_function).filter_prefix == "raw-images/focos/" && one(aws_s3_bucket_notification.this.lambda_function).filter_suffix == ".jpg" && contains(one(aws_s3_bucket_notification.this.lambda_function).events, "s3:ObjectCreated:*")
    error_message = "S3 event notification must trigger Lambda on raw-images/focos/*.jpg creation."
  }
}

run "reject_invalid_kms_arn" {
  command = plan
  variables { kms_key_objects_arn = "invalid-kms-arn" }
  expect_failures = [var.kms_key_objects_arn]
}

run "reject_invalid_iam_role_arn" {
  command = plan
  variables { iam_role_arn = "arn:aws:iam::111122223333:role/*" }
  expect_failures = [var.iam_role_arn]
}
