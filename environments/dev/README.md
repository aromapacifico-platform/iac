# Development infrastructure pattern

This root composes the existing network and security modules with the #24 ingest module and **one** farm module. Test/prod roots remain unchanged. Operational non-secret naming, farm ID and approved network CIDRs live in `terraform.tfvars`; `locals.tf` builds final names. Provider default tags and the existing default AWS provider are retained. Security, ingest and farm receive the explicit `aws.project = aws` mapping.

Dependency order is network -> security -> ingest -> farm. Security policies derive resource ARNs from the same naming inputs instead of taking workload outputs, avoiding a cycle. The role output waits for its inline policy. No remote state or duplicated keys/roles are used.

## External inputs

Supply a real **public device-generated CSR** through `farm_certificate_csr` in an untracked `inputs.local.tfvars` file. Never supply a private key. The existing network contract still requires explicit least-privilege `endpoint_access` grants for S3 and DynamoDB. Use the correct deployed account, roles, bucket and table ARNs; the test-only account IDs are not deployment defaults. An IoT managed action does not traverse the VPC DynamoDB endpoint, so its service role must not be rejected merely for lacking a VPC source endpoint.

The default `farm_certificate_active=false` requests an inactive certificate. Changing it to false after activation represents node deactivation; it does not destroy the identity. Actual resource mutation is not authorized by this repository task.

The current reusable CI workflow accepts tool versions only and does not supply
the CSR or endpoint grants. PR #8 remains open: its environment tfvars and
workflow pinning must be integrated from main after merge. The real public CSR
and its approved delivery to the final #27 pipeline plan remain pending; see
[plan inputs](../../docs/iac/ci-plan-inputs.md). Keep the private key outside
Terraform and never substitute the synthetic mock CSR for operational input.

```bash
terraform init -backend=false
terraform validate
terraform test
# Only with separately supplied read access and public inputs:
terraform plan -var-file=inputs.local.tfvars
```

The backend remains the existing S3 backend; backend-free init is for validation. Tests provide provider mocks, a synthetic CSR and endpoint fixtures. Existing network cases remain and new integration cases exercise the single farm and security naming contract. Both CLI credential mechanisms and real AWS actions remain untouched.

## Boundaries before production

The module implements a raw telemetry landing store, encrypted technical failure queues, and a version-ready threshold table. The complete #12 transactional normalizer/evaluator, durable ACK/outbox, application notification and five-year verified archive remain separate implementation work. No TTL is enabled in their absence. Review the [ingest limitations](../../modules/ingest/README.md) before any production enablement, particularly receipt-level storage and business deduplication, schema validation, operational monitoring and the account's IoT TLS domain policy.
