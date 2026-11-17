# Inputs and prerequisites for the #27 environment plan

The callers `.github/workflows/iac-ci-pr.yml` and
`.github/workflows/iac-cd-platform.yml` invoke the pinned reusable workflows
`aromapacifico-platform/.github/.github/workflows/iac-ci-reusable.yml@v1.1.0`
and `iac-cd-reusable.yml@v1.1.0`. The CI workflow accepts
`terraform-version`, `tflint-version`, and `trivy-version`, running format,
validation, static analysis, and OIDC speculative plans without secret
embedding.

## Endpoint grants and pinning

[PR #8](https://github.com/aromapacifico-platform/iac/pull/8) merged (`23b4a2e`),
integrating explicit S3/DynamoDB `endpoint_access` validation, `@v1.1.0` workflow
pinning, and module composition in `environments/{dev,test,prod}`. Each
environment's `terraform.tfvars` defines least-privilege `endpoint_access`
grants for its CI execution role, while `environments/{dev,test,prod}/locals.tf`
extends `local.gateway_endpoint_policies` with explicit runtime statements for
the module roles (`role-ingest`, `role-focus-func`, `delivery`) over their exact
environment S3 bucket (`fnc-aromapacifico-<env>-s3-focus-conf`) and DynamoDB
tables (`dynamo-telemetry`, `dynamo-thresholds`, `dynamo-expedientes`,
`dynamo-sacos`). Validation rejects wildcard principals, wildcard actions, and
broad table grants.

## Public device CSR

All workload roots (`dev`, `test`, `prod`) require `farm_certificate_csr` with no
default. Each environment `terraform.tfvars` supplies a non-sensitive public
example PKCS#10 PEM CSR (whose private key was discarded and with
`farm_certificate_active = false`) so automated speculative plans run cleanly
without committing private keys. For production provisioning outside CI, an
operator supplies the real device-generated CSR externally (`TF_VAR_` or
untracked `*.local.tfvars`); private keys always remain outside Terraform.

## Speculative plan and Zero-Apply boundary

Speculative plans under Epic 6 (`#27`) execute `terraform fmt`,
`terraform validate`, `terraform test`, and read-only `terraform plan` against
AWS account `273577169715` (`us-east-1`). When remote S3 state buckets
(`aromapacifico-tfstate-<env>`) have not been bootstrapped due to the strict
Zero-Apply mandate, the CD/speculative plan procedure uses a temporary local
backend override strictly for `plan` generation and discards local plan/state
artifacts immediately afterwards without provisioning AWS resources.
