# HU #24 implementation and validation evidence

Initial implementation recorded on 2026-11-10; validation procedure corrected on 2026-11-11. The successful user-reported local execution below supersedes the earlier blocked sandbox attempts for local validation status. Previously recorded tool versions: Terraform CLI 1.16.6, linux_amd64, and AWS provider 6.72.0, matching the existing environment lock and network's >=6.72,<7 requirement. Mocked checks are not evidence of deployed AWS behavior.

## Successful local execution reported by the user (2026-11-11)

The user reported running `bash scripts/validate-hu24.sh` on their own machine after the queue-plan, sensitive-output and GSI fixes. This evidence comes from that local execution, not from the assistant's sandbox. No tests were rerun to make this documentation update.

| Check | User-reported local result |
|---|---|
| Backend-free initializations | PASS: 12 |
| `terraform validate` on configured roots | PASS: 7 |
| Provider-mocked tests | PASS: 58 (44 existing scenarios and 14 HU #24 scenarios) |
| Supplementary checks | PASS: 9 |
| TFLint | PASS: no findings |
| Errors and warnings | None reported |

The local run completed the validation previously blocked in the sandbox, including the corrected queue-policy assertions and sensitive certificate outputs. The earlier IPC failures and incomplete runs remain below as historical evidence; they are not the outcome of this successful local run.

## Workspace and dependencies

| Directory | Actual path | Initial branch/status | Use |
|---|---|---|---|
| Terraform | `/home/juan-david-ocampo/Documentos/Infra/aromaPacifico/iac` | `feat/24-ingest-farm-modules`, clean | Only edited repository |
| Architecture | `/home/juan-david-ocampo/Documentos/Infra/aromaPacifico/planning` | `main`, clean; `4c6fa27` | Read-only source; local checkout predates #12 |
| Instruction package | `/home/juan-david-ocampo/Documentos/Infra/aromaPacifico/IaC` | No `.git` repository | Read-only original instructions/skill/context |

The case-sensitive `IaC` and `iac` paths are different directories. The common parent was not initialized as a repository. Existing branches and tracked changes were preserved. The original AGENTS.md and GEMINI.md are identical, SHA-256 `9cbc51c0c5dae1c8f6e2e1775814899f116c1c6e90d40a6389c2cf62708f842a`; neither was renamed or changed.

The complete [#24 story](https://github.com/aromapacifico-platform/planning/issues/24) was read. Dependencies [#22](https://github.com/aromapacifico-platform/planning/issues/22), [#23](https://github.com/aromapacifico-platform/planning/issues/23) and [#12](https://github.com/aromapacifico-platform/planning/issues/12), including their comments, were checked and are closed. Since the local planning checkout lacks #12's document, its [current GitHub source](https://github.com/aromapacifico-platform/planning/blob/main/docs/architecture/carga-a-ingesta-telemetria.md) was read alongside the provided context snapshot. No planning checkout update was made.

Scope: Workload E6-05/06, allocated 24 human hours in the supplied Epic 6 plan. This allocation is not a measured execution-time claim.

## Adaptation, separate from the story

- New repository `AGENTS.md` integrates the reviewed original guidance, the 26-rule catalog, user restrictions and explicit compatibility decisions.
- The skill is installed at `.agents/skills/aromapacifico-devops/SKILL.md` with its script, references and scaffold. All 26 detailed rule files are bundled. Required architecture snapshots are bundled with explicit GitHub links in place of unavailable sibling-relative document/diagram links. Skill paths do not depend on Antigravity or this user's home directory.
- AWS 5.x examples were changed to AWS 6.x. Existing network's default provider and security's `aws.project` contract remain compatible. Local source/version combinations, incorrect KMS output examples, overly broad egress and stale KMS alias examples were corrected in the adapted copy.
- The validator was read before execution. It now explicitly reports its partial regex/structure scope, skips generated caches and detects workload IAM-role creation. Four supplementary behavior checks passed: nonexistent target, forbidden workload role, ignored cache and missing variable metadata. It is not proof of all 26 rules or a replacement for HCL/IAM/secret analysis.
- No codex.md was created; the original package is unchanged.

## Story implementation

`modules/ingest` creates the exact farm-scoped IoT policy and Basic Ingest rule, KMS-encrypted telemetry and threshold tables, and a KMS-encrypted action-failure reception queue with DLQ and restricted redrive. It consumes `security.kms_key_data_arn` and `security.role_ingest_arn`. Trusted topic/client/principal metadata supplies identity. Receipt-specific sort keys preserve separate raw transmissions with the same event ID rather than overwriting raw history. No untrusted expiry field is selected.

Both tables have on-demand billing, PITR, deletion protection, prevent_destroy and streams. TTL is absent: data remains online until a verified archive can preserve at least five calendar years. The threshold table supports version/pointer/audit records without inventing mutable application data or an alert engine.

`modules/farm` creates one IoT thing, a certificate from a mandatory external public CSR, and its thing/policy attachments. `certificate_active=false` requests real certificate deactivation rather than removing Terraform configuration or ignoring changes. No private-key generation, input, file or output exists. FincaID is a thing attribute and a tag on the farm-specific IoT policy; unsupported tags are not fabricated on thing/certificate resources.

`environments/dev` invokes farm exactly once, retaining network naming, provider defaults, tags and contracts. Root locals compute names that match the existing security IAM targets. Security receives an optional exact rule name, limits SourceArn/SourceAccount, replaces ingestion wildcard KMS actions with exact required actions and scopes them to the same-account DynamoDB/SQS services. Its role output waits for the inline policy. Its IAM-document data source now uses the injected alias. No security-to-workload output dependency was introduced.

New module samples and READMEs describe inputs, public CSR provisioning, encryption, certificate status, retention and limits. The 44 existing Terraform test scenarios remain; 14 new mocked plan scenarios cover #24 and the IAM contract (58 total).

## Provider-context correction (2026-11-11)

The previous script and the ingest/farm READMEs incorrectly instructed callers to run standalone `terraform validate` inside reusable modules declaring `configuration_aliases = [aws.project]`. That declaration accepts a provider from a caller; it does not configure one. During standalone validation Terraform treats that directory as a root, with no calling module to supply `aws.project`. Test mocks are injected during `terraform test`, not during this standalone validation.

The user's `Provider configuration not present` diagnostic is consistent with that invalid validation context. Its generic references to state or removed resources are not evidence that anything is deployed. No deployed state was inspected or changed. In this sandbox, provider schema loading fails earlier on IPC, so the user's exact alias diagnostic could not be reproduced here. These are separate issues: the previous validation procedure was wrong, and the sandbox still prevents completing the corrected procedure.

The configuration review found:

| Context | Required provider / supplied configuration | Result |
|---|---|---|
| ingest/farm reusable modules | Declare and use `aws.project` | Contract retained; no provider blocks added |
| `environments/dev/main.tf` | Both calls map `aws.project = aws` to the root's default AWS provider | Present; no missing mapping |
| ingest/farm samples | Each root configures `aws.principal` and maps `aws.project = aws.principal` | Present; use these roots for schema validation |
| ingest/farm/security unit test files | Each declares `mock_provider "aws"` with `alias = "project"` | Every provider alias referenced by these modules is supplied |
| dev integration tests | Declare default `mock_provider "aws"`; existing module calls forward it as `aws.project` | Alias supplied through the existing root mapping |

During the earlier provider-context correction, all 10 `.tftest.hcl` files, the production module/provider mappings and the `aws.project` declarations remained byte-for-byte unchanged. No assertion was removed or weakened. All 58 existing mocked plan scenarios are retained.

The runner now uses three explicit target lists: 12 backend-free initialization targets, seven configured validation roots and nine mocked test-suite targets. It never validates a reusable child module directly. Network is covered through its environment callers; hybrid is covered through `environments/network`.

Reference: HashiCorp's [provider configuration aliases](https://developer.hashicorp.com/terraform/language/providers/configuration), [test provider injection](https://developer.hashicorp.com/terraform/language/tests#providers), and [validate command](https://developer.hashicorp.com/terraform/cli/commands/validate).

## Queue-plan and sensitive-output fixes and earlier sandbox run (2026-11-11)

The user subsequently ran the full script outside this sandbox and reported two real configuration/test failures. They are distinct from the earlier provider-context problem and sandbox IPC limitation.

1. **Unknown redrive-policy condition:** `aws_sqs_queue.this.redrive_policy` is produced by `jsonencode` and references the computed `aws_sqs_queue.dead_letter.arn`. If that ARN is unknown, the encoded string and even its decoded `maxReceiveCount` cannot be inspected during plan. The test now supplies distinct, valid SQS ARNs, IDs and URLs for the source queue and DLQ using resource-specific `override_resource` blocks with `override_during = plan`. Only computed identities are overridden. Encryption, retention, redrive policy, redrive allow policy and their real resource references remain production configuration. The original assertions are retained; an additional assertion checks the distinct source/DLQ identity and both redrive bindings. Neither policy nor maxReceiveCount is mocked.
2. **Sensitive certificate output:** `modules/farm/outputs.tf` now marks `certificate_pem` with `sensitive = true`, preserving the provider's sensitivity. `modules/farm/sample/outputs.tf` also marks its whole-module reexport sensitive. A new assertion in the existing active-certificate scenario checks `issensitive(output.certificate_pem)`. The dev root exports only thing name/certificate ARN, so it does not reexport the PEM and requires no sensitivity change. No `nonsensitive()` call, private key or provider configuration was added.
3. **Pinned-provider deprecation:** the [AWS 6.72.0 resource schema](https://raw.githubusercontent.com/hashicorp/terraform-provider-aws/v6.72.0/internal/service/dynamodb/table.go) and [versioned documentation](https://raw.githubusercontent.com/hashicorp/terraform-provider-aws/v6.72.0/website/docs/r/dynamodb_table.html.markdown) deprecate GSI `hash_key`/`range_key` in favor of `key_schema`. The history GSI now uses equivalent HASH `history_pk` and RANGE `history_sk` blocks. Table primary keys `pk`/`sk`, GSI name, attributes and projection are unchanged. The table-level `hash_key`/`range_key` remain valid in this pinned schema. No provider/Terraform version or lock file changed. The subsequent user-reported local execution completed without warnings.

The five ingest and six farm scenarios remain; no existing assertion or scenario was removed. Other test suites and the provider alias contracts are unchanged. The full repository still has 58 mocked plan scenarios.

### Earlier targeted sandbox results

| Check | Actual result after these fixes |
|---|---|
| `terraform fmt -check -recursive` | PASS |
| `git diff --check` | PASS |
| Backend-free init, ingest and farm | PASS, AWS 6.72.0 from the existing local mirror, existing locks read-only |
| `terraform -chdir=modules/ingest test -no-color` | BLOCKED, exit 1 before assertions; CLI reports 0 passed, 0 failed |
| `terraform -chdir=modules/farm test -no-color` | BLOCKED, exit 1 before assertions; CLI reports 0 passed, 0 failed |
| `bash scripts/validate-hu24.sh` after these fixes | NOT RUN: both targeted suites must pass first, per the requested execution order |
| Schema validation, TFLint and supplementary expression checks after these fixes | NOT RERUN; earlier results below are historical |

Both targeted test traces fail while creating the AWS provider's local socket:

```text
plugin init error: error="listen unix /tmp/plugin2229943484: setsockopt: operation not permitted"
plugin init error: error="listen unix /tmp/plugin1411886588: setsockopt: operation not permitted"
```

At the time of this sandbox attempt, the fixes had not been verified by completed provider-mocked runs there. No targeted suite, sensitive-output schema check or complete-script run passed in the sandbox. The subsequent successful execution on the user's machine is recorded separately above. No real AWS operation or state modification was performed during the sandbox attempt.

## Earlier provider-context run (before the latest fixes)

These results predate the queue-plan, sensitive-output and GSI changes above; they are retained as history, not current verification.

| Check | Actual result |
|---|---|
| `terraform fmt -check -recursive` | PASS for repository Terraform code |
| Explicit fmt check on hidden skill scaffold | PASS |
| Skill `quick_validate.py` | PASS |
| Partial project validator on ingest/farm | PASS, zero partial findings |
| Partial validator behavior checks (initial 2026-11-10 run) | PASS, 4 checks; not repeated during the provider-context correction |
| `git diff --check` | PASS |
| Backend-free init of 12 module/sample/environment targets | PASS using local provider mirror and existing checksums; no registry download or backend access |
| `terraform validate` on seven configured sample/environment roots | BLOCKED, exit 1 loading provider schemas; no direct child-module validation in the corrected runner |
| `terraform test` with mocks on the 9 targets that have test suites | BLOCKED before assertions; no full mocked scenario has a pass result |
| Supplementary expression-only Terraform tests | PASS: 9 cases, 0 failed; eight selected policy/input cases plus a positive public-CSR case against copied production locals/variables, without AWS resources/provider |
| `tflint --recursive` | TFLint 0.66.0 is now installed; BLOCKED, exit 1: plugin Unix socket creation is prohibited |
| Supplementary HCL parsing (initial 2026-11-10 run) | PASS for 28 new module/sample .tf files; not a provider-schema validation |
| Existing harvest-window pytest suite (initial 2026-11-10 run) | UNAVAILABLE: Python pytest is not installed; source unchanged |

Provider failure diagnosis from the Terraform trace:

```text
plugin init error: error="listen unix /tmp/plugin3227873172: setsockopt: operation not permitted"
```

The same failure occurs on unchanged network code and existing tests. The sandbox prohibits the local socket required by the provider protocol. Network registry discovery is also restricted; backend-free initialization succeeded with the already installed local provider. No sandbox escalation or credential changes were attempted. This failure does not establish whether the changed configuration passes schema validation or all mocked assertions in an unrestricted environment.

The expression-only harness deliberately excludes AWS resource blocks and provider declarations. It checks MQTT permission expressions and invalid farm/CSR/role inputs. It does not validate encryption resource arguments, IAM-to-service runtime permissions, certificate lifecycle or end-to-end flow, and is not counted as successful execution of the 58 provider-mocked scenarios.

## Repeat checks

Run these exact commands in your terminal. Terraform and TFLint must be installed, and provider/plugin downloads must be reachable (or supplied through your own offline mirror). They do not require AWS credentials or public device/dependency values for schema validation and mocked tests. Backend-free initialization writes local dependency metadata only; none of these commands changes deployed state or AWS resources.

```bash
(
  set -e
  cd /home/juan-david-ocampo/Documentos/Infra/aromaPacifico/iac
  terraform -chdir=modules/ingest init -backend=false -input=false
  terraform -chdir=modules/farm init -backend=false -input=false
  terraform -chdir=modules/ingest test -no-color
  terraform -chdir=modules/farm test -no-color
  # Run the complete checks only after both targeted suites succeed.
  tflint --init
  bash scripts/validate-hu24.sh
)
```

The subshell stops on the first failure without closing the calling terminal. In this sandbox both targeted suites were attempted separately for diagnosis; neither passed, so the complete script was not rerun.

After the targeted suites pass, the following commands can run the relevant schema and mocked checks individually from the repository root:

```bash
terraform fmt -check -recursive

# Configured sample roots supply aws.project to the reusable child modules.
for module in ingest farm security; do
  terraform -chdir="modules/$module/sample" init -backend=false -input=false
  terraform -chdir="modules/$module/sample" validate
done

# Unit tests supply mock_provider aws.project, not a real AWS configuration.
for module in ingest farm security; do
  terraform -chdir="modules/$module" init -backend=false -input=false
  terraform -chdir="modules/$module" test
done

# The integration root forwards its default mocked provider to child aliases.
terraform -chdir=environments/dev init -backend=false -input=false
terraform -chdir=environments/dev validate
terraform -chdir=environments/dev test

tflint --recursive
```

The runner additionally validates the test/prod/network environment roots and executes the unchanged network/hybrid/environment test suites. It preserves existing lock files when present, uses backend-free init, runs mocked plan tests and returns nonzero when required checks fail. No provider configuration is inserted into the reusable modules. `TF_CLI_CONFIG_FILE` may point to a caller-owned offline mirror; the sandbox run used the existing local AWS 6.72.0 package instead of registry access. No user CLI or credential configuration was modified.

The supplementary expression-only check can also run independently:

```bash
python3 scripts/check-hu24-expressions.py
```

The [machine-readable results](hu-24-check-results.json) record the earlier sandbox attempts only; that file was not changed in this documentation-only update. The successful user-reported local execution is recorded in the first results section of this document. The configured samples remain the correct validation context.

## Boundaries and pending dependencies

- Local schema validation, all 58 provider-mocked scenarios, nine supplementary checks and TFLint have passed in the user-reported execution. Earlier provider/linter IPC restrictions remain a limitation of the sandbox, not a pending local-validation step. No further test run is needed for this documentation update.
- Real planning requires the actual workload account, explicit endpoint grants, read permissions and a genuine public device-generated CSR. No account or credential fixture is a deployment default. No real AWS plan was run.
- The infrastructure stores raw reception records. The complete #12 normalizer, live/replay scheduling, transactional deduplication/conflict handling, threshold-version selection, durable ACK/outbox and notification flow remain business-processing work. Neither PUBACK nor this raw landing write is an application ACK or proof of a five-minute alert SLA. Satellite/transport adapters and applications were not created.
- Verified archive, immutable five-year retention enforcement and restore evidence are still operational work. Until those exist, TTL stays disabled and storage grows rather than deleting unarchived history. PITR is not a five-year archive.
- Security's other pre-existing role/key/firewall behavior was preserved. This focused change is not a completed audit of all legacy security policies. Verify the actual IoT account domain policy supports TLS 1.2+ before production use.

No apply, destroy, import, AWS mutation, credential modification, commit, push, merge or PR was performed.

## PC-IAC mapping and compatibility decisions

| Rules | Evidence / qualification |
|---|---|
| 001, 023, 026 | Standard ten-file module roots, working input-driven samples, tests; ingest groups the #24 service reception boundary |
| 002, 009, 012, 021, 024, 025 | Validated typed inputs, root tfvars, organized locals, root-built final names |
| 003 | snake_case; established security physical names intentionally exceed historical 28-character target instead of breaking exact IAM grants |
| 004, 005 | Existing default provider tags retained; explicit aws.project injection; FincaID attribute for non-taggable thing |
| 006 | Terraform >=1.11,<2 and AWS 6.x; no downgrade of network/security contracts |
| 007, 016 | Described public outputs, mandatory external CSR, no private-key state path or credentials |
| 008, 010, 014 | Existing backend unchanged; no child backend; protected tables, map for_each and repeated configurable dynamic blocks |
| 011, 017, 019, 022 | Root account discovery and explicit security outputs; no remote state, new workload roles or network resources; security intrinsic metadata/IAM-document exception preserved |
| 013, 015 | Ordered explicit module calls; local sources without version; no remote branch source added |
| 018 | Tests and checks added/preserved; runtime/tool limitations reported instead of claiming compliance |
| 020 | KMS-backed stores/queues, exact ingestion data grants and client/topic permissions; TLS managed by IoT endpoint, with account-policy verification pending |

## Changed-file inventory

### Instruction/skill adaptation

- [.agents/skills/aromapacifico-devops/SKILL.md](../../.agents/skills/aromapacifico-devops/SKILL.md)
- [.agents/skills/aromapacifico-devops/references/context/briefing-inicial-juniors.md](../../.agents/skills/aromapacifico-devops/references/context/briefing-inicial-juniors.md)
- [.agents/skills/aromapacifico-devops/references/context/carga-a-ingesta-telemetria.md](../../.agents/skills/aromapacifico-devops/references/context/carga-a-ingesta-telemetria.md)
- [.agents/skills/aromapacifico-devops/references/hu-examples.md](../../.agents/skills/aromapacifico-devops/references/hu-examples.md)
- [.agents/skills/aromapacifico-devops/references/hu-execution-playbook.md](../../.agents/skills/aromapacifico-devops/references/hu-execution-playbook.md)
- [.agents/skills/aromapacifico-devops/references/project-context.md](../../.agents/skills/aromapacifico-devops/references/project-context.md)
- [.agents/skills/aromapacifico-devops/references/rules-matrix.md](../../.agents/skills/aromapacifico-devops/references/rules-matrix.md)
- [.agents/skills/aromapacifico-devops/references/rules/pc-iac-001.md](../../.agents/skills/aromapacifico-devops/references/rules/pc-iac-001.md)
- [.agents/skills/aromapacifico-devops/references/rules/pc-iac-002.md](../../.agents/skills/aromapacifico-devops/references/rules/pc-iac-002.md)
- [.agents/skills/aromapacifico-devops/references/rules/pc-iac-003.md](../../.agents/skills/aromapacifico-devops/references/rules/pc-iac-003.md)
- [.agents/skills/aromapacifico-devops/references/rules/pc-iac-004.md](../../.agents/skills/aromapacifico-devops/references/rules/pc-iac-004.md)
- [.agents/skills/aromapacifico-devops/references/rules/pc-iac-005.md](../../.agents/skills/aromapacifico-devops/references/rules/pc-iac-005.md)
- [.agents/skills/aromapacifico-devops/references/rules/pc-iac-006.md](../../.agents/skills/aromapacifico-devops/references/rules/pc-iac-006.md)
- [.agents/skills/aromapacifico-devops/references/rules/pc-iac-007.md](../../.agents/skills/aromapacifico-devops/references/rules/pc-iac-007.md)
- [.agents/skills/aromapacifico-devops/references/rules/pc-iac-008.md](../../.agents/skills/aromapacifico-devops/references/rules/pc-iac-008.md)
- [.agents/skills/aromapacifico-devops/references/rules/pc-iac-009.md](../../.agents/skills/aromapacifico-devops/references/rules/pc-iac-009.md)
- [.agents/skills/aromapacifico-devops/references/rules/pc-iac-010.md](../../.agents/skills/aromapacifico-devops/references/rules/pc-iac-010.md)
- [.agents/skills/aromapacifico-devops/references/rules/pc-iac-011.md](../../.agents/skills/aromapacifico-devops/references/rules/pc-iac-011.md)
- [.agents/skills/aromapacifico-devops/references/rules/pc-iac-012.md](../../.agents/skills/aromapacifico-devops/references/rules/pc-iac-012.md)
- [.agents/skills/aromapacifico-devops/references/rules/pc-iac-013.md](../../.agents/skills/aromapacifico-devops/references/rules/pc-iac-013.md)
- [.agents/skills/aromapacifico-devops/references/rules/pc-iac-014.md](../../.agents/skills/aromapacifico-devops/references/rules/pc-iac-014.md)
- [.agents/skills/aromapacifico-devops/references/rules/pc-iac-015.md](../../.agents/skills/aromapacifico-devops/references/rules/pc-iac-015.md)
- [.agents/skills/aromapacifico-devops/references/rules/pc-iac-016.md](../../.agents/skills/aromapacifico-devops/references/rules/pc-iac-016.md)
- [.agents/skills/aromapacifico-devops/references/rules/pc-iac-017.md](../../.agents/skills/aromapacifico-devops/references/rules/pc-iac-017.md)
- [.agents/skills/aromapacifico-devops/references/rules/pc-iac-018.md](../../.agents/skills/aromapacifico-devops/references/rules/pc-iac-018.md)
- [.agents/skills/aromapacifico-devops/references/rules/pc-iac-019.md](../../.agents/skills/aromapacifico-devops/references/rules/pc-iac-019.md)
- [.agents/skills/aromapacifico-devops/references/rules/pc-iac-020.md](../../.agents/skills/aromapacifico-devops/references/rules/pc-iac-020.md)
- [.agents/skills/aromapacifico-devops/references/rules/pc-iac-021.md](../../.agents/skills/aromapacifico-devops/references/rules/pc-iac-021.md)
- [.agents/skills/aromapacifico-devops/references/rules/pc-iac-022.md](../../.agents/skills/aromapacifico-devops/references/rules/pc-iac-022.md)
- [.agents/skills/aromapacifico-devops/references/rules/pc-iac-023.md](../../.agents/skills/aromapacifico-devops/references/rules/pc-iac-023.md)
- [.agents/skills/aromapacifico-devops/references/rules/pc-iac-024.md](../../.agents/skills/aromapacifico-devops/references/rules/pc-iac-024.md)
- [.agents/skills/aromapacifico-devops/references/rules/pc-iac-025.md](../../.agents/skills/aromapacifico-devops/references/rules/pc-iac-025.md)
- [.agents/skills/aromapacifico-devops/references/rules/pc-iac-026.md](../../.agents/skills/aromapacifico-devops/references/rules/pc-iac-026.md)
- [.agents/skills/aromapacifico-devops/scripts/validate_iac_rules.py](../../.agents/skills/aromapacifico-devops/scripts/validate_iac_rules.py)
- [.agents/skills/aromapacifico-devops/templates/module_scaffold/.gitignore](../../.agents/skills/aromapacifico-devops/templates/module_scaffold/.gitignore)
- [.agents/skills/aromapacifico-devops/templates/module_scaffold/CHANGELOG.md](../../.agents/skills/aromapacifico-devops/templates/module_scaffold/CHANGELOG.md)
- [.agents/skills/aromapacifico-devops/templates/module_scaffold/README.md](../../.agents/skills/aromapacifico-devops/templates/module_scaffold/README.md)
- [.agents/skills/aromapacifico-devops/templates/module_scaffold/data.tf](../../.agents/skills/aromapacifico-devops/templates/module_scaffold/data.tf)
- [.agents/skills/aromapacifico-devops/templates/module_scaffold/locals.tf](../../.agents/skills/aromapacifico-devops/templates/module_scaffold/locals.tf)
- [.agents/skills/aromapacifico-devops/templates/module_scaffold/main.tf](../../.agents/skills/aromapacifico-devops/templates/module_scaffold/main.tf)
- [.agents/skills/aromapacifico-devops/templates/module_scaffold/outputs.tf](../../.agents/skills/aromapacifico-devops/templates/module_scaffold/outputs.tf)
- [.agents/skills/aromapacifico-devops/templates/module_scaffold/providers.tf](../../.agents/skills/aromapacifico-devops/templates/module_scaffold/providers.tf)
- [.agents/skills/aromapacifico-devops/templates/module_scaffold/sample/README.md](../../.agents/skills/aromapacifico-devops/templates/module_scaffold/sample/README.md)
- [.agents/skills/aromapacifico-devops/templates/module_scaffold/sample/data.tf](../../.agents/skills/aromapacifico-devops/templates/module_scaffold/sample/data.tf)
- [.agents/skills/aromapacifico-devops/templates/module_scaffold/sample/locals.tf](../../.agents/skills/aromapacifico-devops/templates/module_scaffold/sample/locals.tf)
- [.agents/skills/aromapacifico-devops/templates/module_scaffold/sample/main.tf](../../.agents/skills/aromapacifico-devops/templates/module_scaffold/sample/main.tf)
- [.agents/skills/aromapacifico-devops/templates/module_scaffold/sample/outputs.tf](../../.agents/skills/aromapacifico-devops/templates/module_scaffold/sample/outputs.tf)
- [.agents/skills/aromapacifico-devops/templates/module_scaffold/sample/providers.tf](../../.agents/skills/aromapacifico-devops/templates/module_scaffold/sample/providers.tf)
- [.agents/skills/aromapacifico-devops/templates/module_scaffold/sample/terraform.tfvars](../../.agents/skills/aromapacifico-devops/templates/module_scaffold/sample/terraform.tfvars)
- [.agents/skills/aromapacifico-devops/templates/module_scaffold/sample/variables.tf](../../.agents/skills/aromapacifico-devops/templates/module_scaffold/sample/variables.tf)
- [.agents/skills/aromapacifico-devops/templates/module_scaffold/sample/versions.tf](../../.agents/skills/aromapacifico-devops/templates/module_scaffold/sample/versions.tf)
- [.agents/skills/aromapacifico-devops/templates/module_scaffold/variables.tf](../../.agents/skills/aromapacifico-devops/templates/module_scaffold/variables.tf)
- [.agents/skills/aromapacifico-devops/templates/module_scaffold/versions.tf](../../.agents/skills/aromapacifico-devops/templates/module_scaffold/versions.tf)
- [AGENTS.md](../../AGENTS.md)

### HU #24 implementation, tests and evidence

- [README.md](../../README.md)
- [docs/iac/hu-24-check-results.json](../../docs/iac/hu-24-check-results.json)
- [docs/iac/hu-24-validation.md](../../docs/iac/hu-24-validation.md)
- [environments/dev/README.md](../../environments/dev/README.md)
- [environments/dev/data.tf](../../environments/dev/data.tf)
- [environments/dev/locals.tf](../../environments/dev/locals.tf)
- [environments/dev/main.tf](../../environments/dev/main.tf)
- [environments/dev/outputs.tf](../../environments/dev/outputs.tf)
- [environments/dev/terraform.tfvars](../../environments/dev/terraform.tfvars)
- [environments/dev/tests/ingest.tftest.hcl](../../environments/dev/tests/ingest.tftest.hcl)
- [environments/dev/tests/network.tftest.hcl](../../environments/dev/tests/network.tftest.hcl)
- [environments/dev/variables.tf](../../environments/dev/variables.tf)
- [modules/farm/.gitignore](../../modules/farm/.gitignore)
- [modules/farm/.terraform.lock.hcl](../../modules/farm/.terraform.lock.hcl)
- [modules/farm/CHANGELOG.md](../../modules/farm/CHANGELOG.md)
- [modules/farm/README.md](../../modules/farm/README.md)
- [modules/farm/data.tf](../../modules/farm/data.tf)
- [modules/farm/locals.tf](../../modules/farm/locals.tf)
- [modules/farm/main.tf](../../modules/farm/main.tf)
- [modules/farm/outputs.tf](../../modules/farm/outputs.tf)
- [modules/farm/providers.tf](../../modules/farm/providers.tf)
- [modules/farm/sample/.terraform.lock.hcl](../../modules/farm/sample/.terraform.lock.hcl)
- [modules/farm/sample/README.md](../../modules/farm/sample/README.md)
- [modules/farm/sample/data.tf](../../modules/farm/sample/data.tf)
- [modules/farm/sample/locals.tf](../../modules/farm/sample/locals.tf)
- [modules/farm/sample/main.tf](../../modules/farm/sample/main.tf)
- [modules/farm/sample/outputs.tf](../../modules/farm/sample/outputs.tf)
- [modules/farm/sample/providers.tf](../../modules/farm/sample/providers.tf)
- [modules/farm/sample/terraform.tfvars](../../modules/farm/sample/terraform.tfvars)
- [modules/farm/sample/variables.tf](../../modules/farm/sample/variables.tf)
- [modules/farm/sample/versions.tf](../../modules/farm/sample/versions.tf)
- [modules/farm/tests/farm.tftest.hcl](../../modules/farm/tests/farm.tftest.hcl)
- [modules/farm/variables.tf](../../modules/farm/variables.tf)
- [modules/farm/versions.tf](../../modules/farm/versions.tf)
- [modules/ingest/.gitignore](../../modules/ingest/.gitignore)
- [modules/ingest/.terraform.lock.hcl](../../modules/ingest/.terraform.lock.hcl)
- [modules/ingest/CHANGELOG.md](../../modules/ingest/CHANGELOG.md)
- [modules/ingest/README.md](../../modules/ingest/README.md)
- [modules/ingest/data.tf](../../modules/ingest/data.tf)
- [modules/ingest/locals.tf](../../modules/ingest/locals.tf)
- [modules/ingest/main.tf](../../modules/ingest/main.tf)
- [modules/ingest/outputs.tf](../../modules/ingest/outputs.tf)
- [modules/ingest/providers.tf](../../modules/ingest/providers.tf)
- [modules/ingest/sample/.terraform.lock.hcl](../../modules/ingest/sample/.terraform.lock.hcl)
- [modules/ingest/sample/README.md](../../modules/ingest/sample/README.md)
- [modules/ingest/sample/data.tf](../../modules/ingest/sample/data.tf)
- [modules/ingest/sample/locals.tf](../../modules/ingest/sample/locals.tf)
- [modules/ingest/sample/main.tf](../../modules/ingest/sample/main.tf)
- [modules/ingest/sample/outputs.tf](../../modules/ingest/sample/outputs.tf)
- [modules/ingest/sample/providers.tf](../../modules/ingest/sample/providers.tf)
- [modules/ingest/sample/terraform.tfvars](../../modules/ingest/sample/terraform.tfvars)
- [modules/ingest/sample/variables.tf](../../modules/ingest/sample/variables.tf)
- [modules/ingest/sample/versions.tf](../../modules/ingest/sample/versions.tf)
- [modules/ingest/tests/ingest.tftest.hcl](../../modules/ingest/tests/ingest.tftest.hcl)
- [modules/ingest/variables.tf](../../modules/ingest/variables.tf)
- [modules/ingest/versions.tf](../../modules/ingest/versions.tf)
- [modules/security/README.md](../../modules/security/README.md)
- [modules/security/locals.tf](../../modules/security/locals.tf)
- [modules/security/main.tf](../../modules/security/main.tf)
- [modules/security/outputs.tf](../../modules/security/outputs.tf)
- [modules/security/tests/ingest.tftest.hcl](../../modules/security/tests/ingest.tftest.hcl)
- [modules/security/variables.tf](../../modules/security/variables.tf)
- [scripts/check-hu24-expressions.py](../../scripts/check-hu24-expressions.py)
- [scripts/validate-hu24.sh](../../scripts/validate-hu24.sh)

