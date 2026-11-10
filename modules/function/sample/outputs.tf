# ==============================================================================
# Sample Fixture Outputs (PC-IAC-007)
# ==============================================================================

output "sample_s3_bucket_id" {
  description = "Sample output exposing created confirmation S3 bucket ID."
  value       = module.function.s3_bucket_id
}

output "sample_lambda_function_name" {
  description = "Sample output exposing provisioned Lambda function name."
  value       = module.function.lambda_function_name
}

output "sample_sqs_dlq_arn" {
  description = "Sample output exposing provisioned Dead Letter Queue ARN."
  value       = module.function.sqs_dlq_arn
}

output "sample_iam_role_arn" {
  description = "Sample output exposing effective IAM role ARN."
  value       = module.function.iam_role_arn
}

output "sample_retry_attempts" {
  description = "Sample output exposing configured maximum retry attempts."
  value       = module.function.retry_attempts
}
