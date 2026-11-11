output "policy_name" {
  description = "Exact farm-scoped IoT policy to attach to the certificate."
  value       = aws_iot_policy.this.name
}
output "mqtt_topics" {
  description = "Physical Basic Ingest publish topics; no broker wildcard authorization."
  value       = local.mqtt_topics
}
output "config_topic" {
  description = "Only topic on which the device may subscribe and receive."
  value       = local.config_topic
}
output "tables" {
  description = "Encrypted telemetry and threshold table contracts."
  value       = { for k, t in aws_dynamodb_table.this : k => { name = t.name, arn = t.arn, stream_arn = t.stream_arn } }
}
output "error_queue_url" {
  description = "Technical reception failure queue; not the five-year archive."
  value       = aws_sqs_queue.this.url
}
output "rule_arn" {
  description = "IoT rule ARN authorized by the security role trust policy."
  value       = aws_iot_topic_rule.this.arn
}
