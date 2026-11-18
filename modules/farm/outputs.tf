output "thing_name" {
  description = "Exact MQTT ClientId; connected certificate must be attached to this thing."
  value       = aws_iot_thing.this.name
}
output "certificate_arn" {
  description = "Public certificate identity, with no private key material."
  value       = aws_iot_certificate.this.arn
}
output "certificate_pem" {
  description = "Public signed certificate for external provisioning onto the device."
  value       = aws_iot_certificate.this.certificate_pem
  sensitive   = true
}
output "identity_tags" {
  description = "Governance metadata; thing carries FincaID as an IoT attribute."
  value       = local.tags
}
