output "kms_keys" {
  description = "Map of all customer managed KMS keys created with their key_id, arn and alias."
  value = {
    for k, v in aws_kms_key.this : k => {
      key_id = v.key_id
      arn    = v.arn
      alias  = aws_kms_alias.this[k].name
    }
  }
}

output "kms_key_data_arn" {
  description = "KMS Customer Managed Key ARN for agricultural telemetry and sack master ledger."
  value       = aws_kms_key.this["data"].arn
}

output "kms_key_objects_arn" {
  description = "KMS Customer Managed Key ARN for drone flight binaries, images and inference objects."
  value       = aws_kms_key.this["objects"].arn
}

output "kms_key_logs_arn" {
  description = "KMS Customer Managed Key ARN for CloudWatch audit traces, state locking and flow logs."
  value       = aws_kms_key.this["logs"].arn
}

output "role_ingest_arn" {
  description = "IAM Role ARN for AWS IoT Core to publish telemetry into DynamoDB and SQS."
  value       = aws_iam_role.ingest.arn
}

output "role_focus_function_arn" {
  description = "IAM Role ARN for focus confirmation Lambda execution."
  value       = aws_iam_role.focus_function.arn
}

output "role_delivery_arn" {
  description = "IAM Role ARN for port delivery and sack transaction events."
  value       = aws_iam_role.delivery.arn
}

output "role_flow_logs_arn" {
  description = "IAM Role ARN for VPC Flow Logs publication to CloudWatch Logs."
  value       = aws_iam_role.flow_logs.arn
}

output "security_group_ids" {
  description = "Map of all provisioned Security Group IDs keyed by role."
  value = {
    alb_query    = aws_security_group.alb_query.id
    query        = aws_security_group.query.id
    vpce_api     = aws_security_group.vpce_api.id
    vpce_s3      = aws_security_group.vpce_s3.id
    ingest       = aws_security_group.ingest.id
    function     = aws_security_group.function.id
    vpce_rekog   = aws_security_group.vpce_rekog.id
    clients_log  = aws_security_group.clients_log.id
    vpce_logs    = aws_security_group.vpce_logs.id
    clients_kms  = aws_security_group.clients_kms.id
    vpce_kms     = aws_security_group.vpce_kms.id
    admin        = aws_security_group.admin.id
    vpce_ssm     = aws_security_group.vpce_ssm.id
    resolver_in  = aws_security_group.resolver_in.id
    resolver_out = aws_security_group.resolver_out.id
  }
}

output "nacl_private_id" {
  description = "Network ACL ID protecting private environment subnets."
  value       = aws_network_acl.private.id
}

output "nacl_public_id" {
  description = "Network ACL ID protecting public query subnets."
  value       = aws_network_acl.public.id
}

