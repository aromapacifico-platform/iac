# ==============================================================================
# S3 Confirmation Bucket (PC-IAC-010, PC-IAC-020, Issue #25)
# ==============================================================================

resource "aws_s3_bucket" "this" {
  provider = aws.project

  bucket        = local.bucket_name
  force_destroy = false

  tags = merge(
    local.common_tags,
    {
      Name = local.bucket_name
      Role = "ConfirmationObjectsBucket"
    }
  )

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_versioning" "this" {
  provider = aws.project

  bucket = aws_s3_bucket.this.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  provider = aws.project

  bucket = aws_s3_bucket.this.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = var.kms_key_objects_arn
      sse_algorithm     = "aws:kms"
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "this" {
  provider = aws.project

  bucket = aws_s3_bucket.this.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ==============================================================================
# Dead Letter Queue (SQS DLQ) with CMK Encryption (PC-IAC-020, Issue #25)
# ==============================================================================

resource "aws_sqs_queue" "dlq" {
  provider = aws.project

  name                              = local.dlq_name
  message_retention_seconds         = 1209600 # 14 days
  visibility_timeout_seconds        = 300
  kms_master_key_id                 = var.kms_key_data_arn
  kms_data_key_reuse_period_seconds = 300

  tags = merge(
    local.common_tags,
    {
      Name = local.dlq_name
      Role = "FocusConfirmationDLQ"
    }
  )
}

# ==============================================================================
# CloudWatch Log Group with KMS Encryption & Retention (PC-IAC-020)
# ==============================================================================

resource "aws_cloudwatch_log_group" "this" {
  provider = aws.project

  name              = "/aws/lambda/${local.lambda_function_name}"
  retention_in_days = var.log_retention_in_days
  kms_key_id        = var.kms_key_logs_arn != "" ? var.kms_key_logs_arn : null

  tags = merge(
    local.common_tags,
    {
      Name = "/aws/lambda/${local.lambda_function_name}"
    }
  )
}

# ==============================================================================
# Lambda Serverless Compute - Pattern FN-CONF-FOCO (PC-IAC-020, PC-IAC-022, Issue #25)
# IAM Role is owned by the Security domain and injected via var.iam_role_arn.
# ==============================================================================

resource "aws_lambda_function" "this" {
  provider = aws.project

  function_name    = local.lambda_function_name
  description      = "Pattern serverless function for agricultural rust spot confirmation and fitosanitary record updates"
  role             = var.iam_role_arn
  runtime          = "python3.12"
  handler          = "handler.lambda_handler"
  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  memory_size      = var.lambda_memory_size
  timeout          = var.lambda_timeout

  dead_letter_config {
    target_arn = aws_sqs_queue.dlq.arn
  }

  tracing_config {
    mode = "Active"
  }

  dynamic "vpc_config" {
    for_each = length(var.subnet_ids) > 0 ? [1] : []
    content {
      subnet_ids         = var.subnet_ids
      security_group_ids = var.security_group_ids
    }
  }

  environment {
    variables = {
      EXPEDIENTES_TABLE_NAME     = var.expedientes_table_name
      REKOGNITION_MIN_CONFIDENCE = tostring(var.rekognition_min_confidence)
      INFERENCE_MODEL_ID         = var.inference_model_id
      DLQ_URL                    = aws_sqs_queue.dlq.url
      ENVIRONMENT                = var.environment
      PROJECT                    = var.project
    }
  }

  tags = merge(
    local.common_tags,
    {
      Name = local.lambda_function_name
    }
  )

  depends_on = [
    aws_cloudwatch_log_group.this
  ]
}

# ==============================================================================
# Asynchronous Invocations Config: Retries & Dead Letter Destination (Issue #25)
# ==============================================================================

resource "aws_lambda_function_event_invoke_config" "this" {
  provider = aws.project

  function_name                = aws_lambda_function.this.function_name
  maximum_retry_attempts       = 2
  maximum_event_age_in_seconds = 21600

  destination_config {
    on_failure {
      destination = aws_sqs_queue.dlq.arn
    }
  }
}

# ==============================================================================
# S3 Event Trigger Notification & Invocations Permission (Issue #25)
# ==============================================================================

resource "aws_lambda_permission" "allow_s3" {
  provider = aws.project

  statement_id  = "AllowS3BucketFocusNotification"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.this.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.this.arn
}

resource "aws_s3_bucket_notification" "this" {
  provider = aws.project

  bucket = aws_s3_bucket.this.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.this.arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = var.notification_filter_prefix
    filter_suffix       = var.notification_filter_suffix
  }

  depends_on = [
    aws_lambda_permission.allow_s3
  ]
}
