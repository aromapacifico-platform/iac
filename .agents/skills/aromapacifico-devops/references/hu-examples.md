# Repository-compatible examples

Use the current module interfaces as the authority. Network accepts the default AWS provider; security, ingest and farm accept aws.project. Do not rename existing provider configurations.

```hcl
module "ingest" {
  source = "../../modules/ingest"
  providers = { aws.project = aws }

  kms_key_arn     = module.security.kms_key_data_arn
  ingest_role_arn = module.security.role_ingest_arn
  # Supply remaining names and account metadata from root locals/inputs.
}
```

Local module sources never use `version`. Registry modules use a version constraint; Git sources use `?ref=vX.Y.Z`.

IoT policy resources must list exact client and physical Basic Ingest topics for the authorized farm. Do not allow `iot:*`, `topic/*` or publish permission on ACK/config topics. SQS and DynamoDB use the data key from security; the service role needs the precise KMS actions required by the integration. External CSRs keep private keys outside Terraform.

Security groups use only the approved permanent firewall rules. Never add universal 0.0.0.0/0 egress as scaffold boilerplate. Ingestion does not require putting IoT Core or DynamoDB in a subnet.

Five-year retention is preserved conservatively with no TTL deletion until the archive workflow has been implemented and verified. A 90-day TTL is not a substitute for an archive.
