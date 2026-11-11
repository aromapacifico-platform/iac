# External inputs for the HU #24 CI plan

The caller is `.github/workflows/iac-ci-pr.yml` in `aromapacifico-platform/iac`.
It calls `aromapacifico-platform/.github/.github/workflows/iac-ci-reusable.yml@main`.
The real AWS plan requires public external inputs in addition to the committed
`environments/<env>/terraform.tfvars`. No deployment defaults are added.

## Configuration to supply

Configure these **repository Actions variables** in `aromapacifico-platform/iac`
(Settings -> Secrets and variables -> Actions -> Variables). Organization variables
with access to this repository also work. These are public configuration, not AWS
credentials. Environment-scoped variables are not selected by this CI matrix:
the plan jobs do not declare a GitHub `environment`.

| Actions variable | Reusable workflow string input | Plan process environment | Required in |
| --- | --- | --- | --- |
| `ENDPOINT_ACCESS_DEV` | `endpoint-access-dev` | `TF_VAR_endpoint_access` | dev |
| `ENDPOINT_ACCESS_TEST` | `endpoint-access-test` | `TF_VAR_endpoint_access` | test |
| `ENDPOINT_ACCESS_PROD` | `endpoint-access-prod` | `TF_VAR_endpoint_access` | prod |
| `FARM_CERTIFICATE_CSR_DEV` | `farm-certificate-csr-dev` | `TF_VAR_farm_certificate_csr` | dev only |

The caller passes each variable explicitly through `with`. The central workflow
selects the matching endpoint input using `matrix.environment` and sets `TF_VAR_*`
only on `Execute Terraform Speculative Plan`. It passes an empty CSR value for
test/prod, whose roots do not declare that input. Missing configuration fails the
selected plan; another environment's grants are never used as a fallback.

### Endpoint grants: JSON object

Each `ENDPOINT_ACCESS_<ENV>` must contain the **whole JSON object**, with exactly
the keys `s3` and `dynamodb`. Each value has three nonempty arrays of strings:
`principal_arns`, `actions`, and `resource_arns`. Do not supply an IAM policy
document, a JSON string containing JSON, or an `endpoint_access =` HCL assignment.
JSON may be single-line or formatted across lines.

The following is a format template, **not a usable configuration**. Replace every
angle-bracket placeholder with a value approved for that specific environment:

```json
{
  "s3": {
    "principal_arns": ["arn:aws:iam::<ACCOUNT_ID>:role/<APPROVED_ROLE_PATH_AND_NAME>"],
    "actions": ["s3:<APPROVED_ACTION>"],
    "resource_arns": ["arn:aws:s3:::<ACTUAL_BUCKET>/<EXACT_OBJECT_KEY>"]
  },
  "dynamodb": {
    "principal_arns": ["arn:aws:iam::<ACCOUNT_ID>:role/<APPROVED_ROLE_PATH_AND_NAME>"],
    "actions": ["dynamodb:<APPROVED_ACTION>"],
    "resource_arns": ["arn:aws:dynamodb:us-east-1:<ACCOUNT_ID>:table/<ACTUAL_TABLE_NAME>"]
  }
}
```

Security and the workload owners must supply the actual account IDs, IAM role
ARNs, service actions and bucket/object/table/index ARNs. Include bucket-level
ARNs only for the approved bucket-level actions and object-level ARNs for object
actions. Retain the existing Terraform validations and policy construction in all
three roots. This change introduces no wildcard grants, fake ARNs or new roles.
The OIDC plan role is not automatically a workload endpoint principal. The IoT
managed DynamoDB action does not traverse a VPC gateway endpoint.

### Device CSR: raw multiline PEM

`FARM_CERTIFICATE_CSR_DEV` must be the complete **public PKCS#10 CSR**, generated
by the device provisioning owner for the configured farm `CAU-F001`. The device's
private key stays with its owner and never enters GitHub configuration or Terraform.
Paste the raw PEM with real newline characters, its base64 body, and these exact
boundary lines:

```text
-----BEGIN CERTIFICATE REQUEST-----
<COMPLETE_BASE64_ENCODED_PUBLIC_CSR_BODY>
-----END CERTIFICATE REQUEST-----
```

Do not JSON-quote the PEM, encode literal `\n` characters, base64-encode the whole
file, provide an issued certificate, or append any private key. The central plan
step checks the PEM header, rejects private-key markers anywhere in the input,
and verifies CSR parsing and its self-signature using OpenSSL before Terraform:

```sh
set -o pipefail
openssl req -in device.csr.pem -verify -noout 2>&1 |
  grep -qx 'Certificate request self-signature verify OK'
```

The success marker is checked as well as the pipeline status because
[OpenSSL versions before 3.3 can return zero on signature failure](https://docs.openssl.org/3.6/man1/openssl-req/#history).
This verifies the CSR format and signature; the device owner must still confirm
its origin and farm assignment. The synthetic `QUJD` CSR in the existing mock
tests is deliberately invalid for the real provider and is rejected by this check.
CI does not generate a replacement CSR or key. `farm_certificate_active = false`
remains the committed dev setting.

## What exists and what remains external

The inspection covered the local IaC checkout and planning architecture, HU #24
and dependencies #12/#22/#23, and the central workflow on `main` (Git blob
`a5ed4e23398db861b21eb560113cca511868e261`).

| Evidence available | Status |
| --- | --- |
| Region `us-east-1`, environment CIDRs/AZs, dev `client`, `project`, `farm_id`, security CIDRs and inactive certificate setting | Committed operational configuration in environment tfvars |
| Dev resource names and role/KMS output wiring | Derived from existing code; not proof that resources are deployed |
| S3 backend names/KMS settings | Committed backend configuration; the reported run returns `NoSuchBucket`, so bucket existence must not be assumed |
| OIDC selection via `AWS_ROLE_ARN_DEV`, `AWS_ROLE_ARN_TEST`, `AWS_ROLE_ARN_PROD` variables or existing secrets | Existing central mechanism, unchanged; credential values were not read or modified |
| Complete approved endpoint grants for dev/test/prod | Absent from the reviewed source configuration; team must supply the three JSON objects above |
| Valid device CSR for dev | Absent from the reviewed source configuration; device owner must supply the public PEM above |
| Account IDs, ARNs and synthetic CSR in `tests/` and sample fixtures | Test/example data, never operational input sources |

Repository Actions variable/secret values were not inspected, so this inventory
does not certify their current settings. Configure or verify the four named public
variables without printing credentials or secret values. Test/prod do not need a
farm CSR for their current roots.

## Central workflow handoff

The central repository is not available as a local checkout. The exact patch is
[`patches/iac-ci-reusable-plan-inputs.patch`](patches/iac-ci-reusable-plan-inputs.patch),
against the inspected `main` blob above. It changes only
`.github/workflows/iac-ci-reusable.yml` **inside `aromapacifico-platform/.github`**.
Its GitHub path is therefore
`aromapacifico-platform/.github/.github/workflows/iac-ci-reusable.yml`.

From a checkout of that central repository, check and apply the delivered patch:

```sh
git apply --check /path/to/iac/docs/iac/patches/iac-ci-reusable-plan-inputs.patch
git apply /path/to/iac/docs/iac/patches/iac-ci-reusable-plan-inputs.patch
```

The central input declarations must be available at the caller's `@main` reference
before the updated caller can run; otherwise GitHub rejects unknown workflow
inputs. The patch has not been published or applied to the remote repository.

The existing OIDC failure gate, real `terraform plan -input=false`, plan failure
propagation, and S3-to-temporary-local-backend fallback are preserved. The fallback
addresses the reported missing state bucket and still uses the real AWS provider;
it is a speculative plan with no remote-state baseline. It does not create a
bucket or prove that a deployment is safe. No new `continue-on-error` is added;
the existing FinOps-only tolerances are outside this change.

## Validation boundaries

All 58 existing Terraform test runs and their provider mocks are preserved.
`bash scripts/validate-hu24.sh` runs the independent local validation suite; its
mock results do not establish that the OIDC plan can read AWS or that external
inputs are operationally correct. The workflow continues to execute the real
provider plan after the inputs have been supplied. See
[`ci-plan-inputs-validation.md`](ci-plan-inputs-validation.md) for checks performed
on this change and environment limitations.

GitHub documents [reusable workflow input and environment behavior](https://docs.github.com/en/actions/reference/workflows-and-actions/reusing-workflow-configurations).
HashiCorp documents [TF_VAR input and complex value syntax](https://developer.hashicorp.com/terraform/language/values/variables).
