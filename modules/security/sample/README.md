# Sample Usage - Security Reference Module

This sample directory provides an isolated test fixture demonstrating how to consume the `modules/security` reference module in accordance with the PC-IAC-013, PC-IAC-021, and PC-IAC-026 standards.

## Execution Pattern

1. `terraform.tfvars`: Contains pure environment variables without governance logic.
2. `locals.tf`: Enforces client, project, and naming governance standards.
3. `main.tf`: Executes the module invocation with ordered sections A to E.

## Validation Steps

Run the following commands within this directory:

```bash
terraform init
terraform validate
terraform plan
```

