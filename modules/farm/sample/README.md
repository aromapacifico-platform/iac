# Farm sample

This backend-free sample demonstrates the repository provider mapping and tfvars-to-locals naming flow. It does not create security or network dependencies. Supply the remaining module inputs through an untracked `inputs.local.tfvars` file, then use `terraform init -backend=false` and `terraform plan -var-file=inputs.local.tfvars` only when authorized for read access.

Never run apply as validation. For credential-free checks run the module's provider-mocked tests from its parent directory. The farm sample requires a real public device CSR and existing farm-scoped policy name; the ingest sample requires the actual security data key ARN and ingestion role ARN. No account or credential fixture is embedded in sample deployment inputs.


## Schema validation without AWS access

From the repository root:

```bash
terraform -chdir=modules/farm/sample init -backend=false -input=false
terraform -chdir=modules/farm/sample validate
```

This root configures `aws.principal` and passes it to the child as `aws.project`. `validate` checks the complete provider context without connecting to AWS or requiring the public inputs used for a real plan. Do not substitute `terraform -chdir=modules/farm validate`; that directory intentionally has no provider configuration. Run mocked unit tests with `terraform -chdir=modules/farm test` after backend-free initialization of that directory. The tests supply the child's `project` alias directly.
