# HU #24 CI input integration validation

Validation date: 2026-11-11. Branch preserved:
`feat/24-ingest-farm-modules`. No commits, pushes, PRs, credential changes or AWS
mutations were performed. No real AWS plan was run: the approved endpoint grants
and public device CSR remain external prerequisites.

## Checks passed

- `terraform fmt -check -recursive` and `git diff --check`.
- The delivered central patch passes `git apply --check` against the inspected
  central `main` source (blob `a5ed4e23398db861b21eb560113cca511868e261`). Applying
  it in a temporary directory reproduces the proposed workflow exactly.
- Both workflow YAML documents parse. All four caller inputs match central string
  declarations. The matrix expression selects the matching environment's grants.
  The patched plan shell passes `bash -n`.
- An offline temporary regression harness executes the patched plan step with a
  Terraform command stub. Its 27 workflow/shell checks cover contracts, exact delivery
  of JSON/multiline PEM, missing and malformed input, rejection of the existing
  synthetic CSR, invalid CSR signature, private-key input and an appended private
  key marker, OIDC failure, the remote-to-local init fallback, fallback init
  failure and propagation of a failing plan without running `show`. Input bodies
  are not printed. The ephemeral test CSR is used only in this harness; it is
  not saved as CI configuration or offered as an operational device CSR.
- Copies of the unchanged `endpoint_access` variable validation from each actual
  environment root pass **21 isolated Terraform checks**: explicit grants,
  wildcard role, wildcard action, wildcard S3 resource, wildcard DynamoDB
  resource, empty actions and missing service (seven per environment). These use
  no providers or resources and are separate from the existing provider tests.
- The nine existing supplementary expression-only checks run by
  `scripts/check-hu24-expressions.py` pass (four ingest, five farm).
- Existing Terraform variable definitions, resource code, lockfiles and all
  **58 existing provider-mocked Terraform test runs** are unchanged. Changes to
  committed tfvars contain comments only; their operational values are preserved.

The temporary regression harness and local logs are available in this workspace
at `/tmp/aroma-check-ci-plan-inputs.py`,
`/tmp/aroma-ci-plan-inputs-regression.log` and
`/tmp/aroma-hu24-ci-validation.log`. The harness does not replace Terraform or
install a stub in the repository, PATH configuration or workflow. The central
workflow still calls the real Terraform CLI and AWS provider. Workflow static
inspection is not a GitHub-hosted workflow execution or an actionlint result.

## Checks blocked by the execution environment

`bash scripts/validate-hu24.sh` was attempted and returned failure. Backend-free
initialization cannot reach `registry.terraform.io`: this environment rejects
network socket creation. Schema validation and all nine provider-mocked test
targets cannot start the installed AWS provider plugin. TFLint also fails its
plugin startup. These are not reported as successful checks. The 58 test runs
are preserved, but a fresh passing provider-suite result is **not** established
by this session. Gitleaks and Trivy are not installed in this environment.

Rerun the existing suite on a runner that permits provider/plugin execution:

```sh
bash scripts/validate-hu24.sh
```

Then run the CI workflow only after the central patch and the four public Actions
variables described in [the input contract](ci-plan-inputs.md) are available.
Mock checks do not verify the operational device CSR, approved IAM grants,
OIDC/read permissions, backend existence or AWS plan success. No failure control
is disabled to bypass these prerequisites.
