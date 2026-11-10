output "sample_kms_key_data_arn" {
  description = "Sample output exposing telemetry KMS key ARN."
  value       = module.security.kms_key_data_arn
}

output "sample_role_focus_function_arn" {
  description = "Sample output exposing focus confirmation Lambda role ARN."
  value       = module.security.role_focus_function_arn
}

output "sample_security_group_ids" {
  description = "Sample output exposing map of provisioned Security Group IDs."
  value       = module.security.security_group_ids
}
