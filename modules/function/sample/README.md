# Sample Fixture: Focus Confirmation Function Module

This directory provides a functional execution fixture for `modules/function` complying with `PC-IAC-026`.

## Architecture Flow

`terraform.tfvars` (pure configuration)
  --> `variables.tf` (schema and type definition)
    --> `locals.tf` (governance transformation and naming construction)
      --> `main.tf` (module invocation passing `local.*`)

## Verification Commands

```bash
terraform fmt -check
terraform init -backend=false
terraform validate
```
