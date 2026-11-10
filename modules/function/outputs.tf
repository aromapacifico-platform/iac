# ==============================================================================
# Module Outputs (PC-IAC-007)
# ==============================================================================

output "s3_bucket_id" {
  description = "Identifier of the S3 bucket created for confirmation images."
  value       = aws_s3_bucket.this.id
}

output "s3_bucket_arn" {
  description = "ARN of the S3 bucket created for confirmation images."
  value       = aws_s3_bucket.this.arn
}

output "lambda_function_name" {
  description = "Name of the focus confirmation Lambda function."
  value       = aws_lambda_function.this.function_name
}

output "lambda_function_arn" {
  description = "ARN of the focus confirmation Lambda function."
  value       = aws_lambda_function.this.arn
}

output "sqs_dlq_id" {
  description = "URL/Identifier of the Dead Letter Queue for failed invocations."
  value       = aws_sqs_queue.dlq.id
}

output "sqs_dlq_arn" {
  description = "ARN of the Dead Letter Queue for failed invocations."
  value       = aws_sqs_queue.dlq.arn
}

output "cloudwatch_log_group_name" {
  description = "Name of the CloudWatch log group created for function audit logs."
  value       = aws_cloudwatch_log_group.this.name
}

output "cloudwatch_log_group_arn" {
  description = "ARN of the CloudWatch log group created for function audit logs."
  value       = aws_cloudwatch_log_group.this.arn
}

output "iam_role_arn" {
  description = "Effective IAM role ARN utilized by the focus confirmation function."
  value       = local.effective_role_arn
}

output "retry_attempts" {
  description = "Configured maximum retry attempts for asynchronous invocations before DLQ routing."
  value       = aws_lambda_function_event_invoke_config.this.maximum_retry_attempts
}

