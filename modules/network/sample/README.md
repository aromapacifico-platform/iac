# Network Module Sample (PC-IAC-026)

This directory demonstrates how to consume `modules/network` following the `PC-IAC-026` transformation flow:
`terraform.tfvars -> variables.tf -> data.tf -> locals.tf -> main.tf -> ../`.

## Validation
```bash
terraform init -backend=false
terraform validate
```
