# iac

Terraform for the AromaPacífico coffee traceability platform on AWS. This is an academic
case; it is not an official project of the Federación Nacional de Cafeteros.

The architecture and the 100-hour plan live in
[`planning`](https://github.com/aromapacifico-platform/planning). Work is tracked on the
[board](https://github.com/orgs/aromapacifico-platform/projects/2).

## Layout

```
bootstrap/                 State bucket and KMS key, applied once per account
modules/                   Reusable modules (network, security, ingest, farm, function)
environments/
  dev/                     AromaPacifico-Dev account,  10.50.0.0/16
  test/                    AromaPacifico-Test account, 10.60.0.0/16
  prod/                    AromaPacifico-Prod account, 10.70.0.0/16
```

Each environment has the same files:

| File | Purpose |
| --- | --- |
| `versions.tf` | Terraform and provider constraints |
| `backend.tf` | Empty `s3` backend; values come from `backend.hcl` |
| `backend.hcl` | Bucket, key, KMS alias and lock settings for that account |
| `providers.tf` | AWS provider with the mandatory landing zone tags |
| `variables.tf` | Inputs with validation |
| `terraform.tfvars` | Non-sensitive values for the environment |
| `main.tf` | Locals and module calls |
| `outputs.tf` | Values other stacks or reviewers need |

## Requirements

- Terraform `>= 1.11, < 2.0` for network and environment roots (plan-time mocks);
  the independent bootstrap root retains its `>= 1.10` baseline for native S3 locking.
- AWS credentials from IAM Identity Center locally, or the OIDC role in the pipeline.
  No access keys are stored in this repository or in any `tfvars` file.
- [pre-commit](https://pre-commit.com), [TFLint](https://github.com/terraform-linters/tflint)
  and [gitleaks](https://github.com/gitleaks/gitleaks)

## Remote state

Every workload root targets its own bucket `aromapacifico-tfstate-<env>` and KMS key
`alias/aromapacifico-tfstate`, defined by `bootstrap/`. Configuration alone does not
prove they exist. The CI speculative plan retains its temporary local backend
fallback for the reported missing S3 bucket; no bootstrap is performed by this fix.
The configured remote-state controls are:

- The bucket is versioned, blocks public access, enforces TLS and encrypts with SSE-KMS by
  default. Old state versions expire after 90 days.
- The backend sets `encrypt = true`, `kms_key_id` and `use_lockfile = true`, so two runs on
  the same environment cannot write the state at the same time.

Keeping one state per account means a plan in dev can never lock or overwrite prod.

### Bootstrap an account (once)

```sh
cd bootstrap
terraform init
terraform apply -var environment=dev
```

The bootstrap state is local and ignored by git. If it is lost, import the bucket and key
again; nothing else depends on it.

## Working on an environment

```sh
cd environments/dev
terraform init -backend-config=backend.hcl
terraform plan
```

`terraform.tfvars` is loaded automatically. Values that are sensitive or personal go in an
ignored file (`*.auto.tfvars`, `*.local.tfvars` or `secrets.tfvars`) or come from the
pipeline as `TF_VAR_*`; they are never committed.

The reusable CI workflow accepts tool versions only. Approved endpoint grants
and the public device CSR remain prerequisites for the final plan in #27; see
[plan inputs and pending integration](docs/iac/ci-plan-inputs.md). Mock test
fixtures are not deployment inputs.

## Tags

The provider applies the mandatory tags of the landing zone to every resource:

| Tag | Default | Overridden by |
| --- | --- | --- |
| `FincaID` | `GLOBAL` | Farm resources |
| `DronID` | `NO-APLICA` | Drone resources |
| `AcopioID` | `MULTICENTRO` | Collection center resources |
| `ViajeID` | `NO-APLICA` | Trip resources |
| `Ambiente` | `desarrollo` / `pruebas` / `produccion` | — |
| `Propietario` | `devops-fnc` | `owner` variable |
| `Proyecto` | `AromaPacifico` | — |

## Pre-commit

```sh
pre-commit install
pre-commit run --all-files
```

The hooks run `terraform fmt`, TFLint with the AWS ruleset, private key detection and
gitleaks. A commit that contains a credential is rejected before it reaches the remote.

## Conventions

- Code, commits and branches in English; Conventional Commits (`feat(network): ...`).
- Branch names: `feat/<issue>-<short-name>`, one issue per pull request.
- Every pull request shows a clean `terraform fmt`, `validate` and TFLint run; `plan` runs in
  the pipeline ([#26](https://github.com/aromapacifico-platform/planning/issues/26)).

## Environment network (planning #22)

The dev/test/prod roots now instantiate `modules/network`. Supply actual scoped
`endpoint_access` grants before a real plan; no test endpoint policy is used for
deployment. Hybrid connectivity defaults to disabled. Only production may receive
the shared central TGW ID. `environments/network` is a separate central-account
root with an explicit account/role and dedicated backend, never the dev profile
by assumption. See [the network README](modules/network/README.md) for addressing,
inputs/outputs, both VPN tunnels, Secrets Manager PSK handling, security/DNS
contracts, mock tests and deployment prerequisites.


## Farm and telemetry infrastructure (#24)

The [dev root](environments/dev/README.md) now wires one [farm](modules/farm/README.md) and [ingest](modules/ingest/README.md) pattern to existing network/security contracts. The device's private key stays outside Terraform, MQTT authorization is farm-specific, and the tables have no TTL pending verified five-year archival. See [validation evidence and remaining limits](docs/iac/hu-24-validation.md).
