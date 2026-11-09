output "state_bucket" {
  description = "Bucket to set as `bucket` in environments/<env>/backend.hcl."
  value       = aws_s3_bucket.state.id
}

output "state_kms_key_arn" {
  description = "KMS key that encrypts the state."
  value       = aws_kms_key.state.arn
}

output "state_kms_alias" {
  description = "Alias to set as `kms_key_id` in environments/<env>/backend.hcl."
  value       = aws_kms_alias.state.name
}
