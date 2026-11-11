# HU #24 implementation and validation evidence

Historical implementation evidence from 2026-11-10/11. The user previously
reported seven configured-root validations, 58 provider-mocked test scenarios
and TFLint passing locally. These are historical results, not a fresh run of the
current integration. Current review checks are reported with the review response.
Provider mocks do not establish deployed AWS behavior or a clean AWS plan.

Scope: Workload E6-05/06, allocated 24 human hours in the Epic 6 plan; this is
not a measured execution-time claim. The Terraform module and environment tests
remain in their `tests/` directories. Validate aliased modules through their
configured samples, then run `terraform test` with their provider mocks.

## Story implementation

`modules/ingest` creates the exact farm-scoped IoT policy and Basic Ingest rule, KMS-encrypted telemetry and threshold tables, and a KMS-encrypted action-failure reception queue with DLQ and restricted redrive. It consumes `security.kms_key_data_arn` and `security.role_ingest_arn`. Trusted topic/client/principal metadata supplies identity. Receipt-specific sort keys preserve separate raw transmissions with the same event ID rather than overwriting raw history. No untrusted expiry field is selected.

Both tables have on-demand billing, PITR, deletion protection, prevent_destroy and streams. TTL is absent: data remains online until a verified archive can preserve at least five calendar years. The threshold table supports version/pointer/audit records without inventing mutable application data or an alert engine.

`modules/farm` creates one IoT thing, a certificate from a mandatory external public CSR, and its thing/policy attachments. `certificate_active=false` requests real certificate deactivation rather than removing Terraform configuration or ignoring changes. No private-key generation, input, file or output exists. FincaID is a thing attribute and a tag on the farm-specific IoT policy; unsupported tags are not fabricated on thing/certificate resources.

`environments/dev` invokes farm exactly once, retaining network naming, provider defaults, tags and contracts. Root locals compute names that match the existing security IAM targets. Security receives an optional exact rule name, limits SourceArn/SourceAccount, replaces ingestion wildcard KMS actions with exact required actions and scopes them to the same-account DynamoDB/SQS services. Its role output waits for the inline policy. Its IAM-document data source now uses the injected alias. No security-to-workload output dependency was introduced.

New module samples and READMEs describe inputs, public CSR provisioning, encryption, certificate status, retention and limits. The 44 existing Terraform test scenarios remain; 14 new mocked plan scenarios cover #24 and the IAM contract (58 total).

## Boundaries and pending dependencies

- Real planning requires the actual workload account, explicit endpoint grants, read permissions and a genuine public device-generated CSR. No account or credential fixture is a deployment default. No real AWS plan was run.
- The infrastructure stores raw reception records. The complete #12 normalizer, live/replay scheduling, transactional deduplication/conflict handling, threshold-version selection, durable ACK/outbox and notification flow remain business-processing work. Neither PUBACK nor this raw landing write is an application ACK or proof of a five-minute alert SLA. Satellite/transport adapters and applications were not created.
- Verified archive, immutable five-year retention enforcement and restore evidence are still operational work. Until those exist, TTL stays disabled and storage grows rather than deleting unarchived history. PITR is not a five-year archive.
- Security's other pre-existing role/key/firewall behavior was preserved. This focused change is not a completed audit of all legacy security policies. Verify the actual IoT account domain policy supports TLS 1.2+ before production use.



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
