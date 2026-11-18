# Telemetry ingestion infrastructure

Implements the infrastructure boundary of [planning #24](https://github.com/aromapacifico-platform/planning/issues/24), using the farm topic and data-retention contracts from [#12](https://github.com/aromapacifico-platform/planning/issues/12). Requires Terraform >=1.11,<2 and AWS >=6.72,<7.

The pattern receives cultivation (`cultivo`) and drying (`secado`) readings through AWS IoT Core Basic Ingest over mutual TLS. A farm-scoped policy permits only the exact ClientId and the two physical publish topics returned by `mqtt_topics`. The certificate must be attached to the named thing. The device may subscribe/receive only its own ordinary `/config` topic; it cannot publish acknowledgements or configuration.

The rule explicitly selects payload fields and derives identity and storage keys from the authorized topic. It writes a **landing record** using DynamoDBv2 into an on-demand telemetry table. SQL uses `pk=DEVICE#{farm_id}`, `sk=EVENT#{event_id}#RECEIPT#{traceid()}`, with a `history` GSI keyed by farm/kind/day and original time/event/receipt ID. The trusted IoT receipt ID keeps retransmissions or conflicting payloads with the same event ID as separate landing records instead of overwriting the original history. The single pattern treats its farm ID as its device ID. `occurred_at` must be an ISO-8601 UTC string and event IDs must be stable. Schema validation beyond required IDs/time, clock validation, calibration and agricultural evaluation belong to the future consumer.

Action failures enter a KMS-encrypted standard SQS queue, with 14-day retention, 180-second visibility and redrive to a similarly encrypted DLQ after five receives. The DLQ accepts redrive only from that queue. This is a technical failure path, not a five-year archive or a business consumer. An error-action failure still requires operational monitoring; this module cannot guarantee delivery after both AWS actions fail.

Both tables use `security.kms_key_data_arn`, deletion protection, `prevent_destroy`, PITR and `NEW_AND_OLD_IMAGES` streams. The thresholds table has string `pk`/`sk` for immutable versions, the active environment pointer and audit records described in #12. It is intentionally empty: future authorized federation tooling must publish validated versions atomically and record changes. Terraform does not own mutable threshold items, contacts or application data. The device has no threshold-table access.

## Security dependencies and names

The caller supplies `kms_key_arn`, `ingest_role_arn`, the actual workload account/region, farm ID, ClientId/thing name and final `resource_names`. The dev root consumes the actual security outputs `kms_key_data_arn` and `role_ingest_arn`; no role or key is created here.

Existing security IAM grants require these exact names: `${client}-${project}-${environment}-dynamo-telemetry` and `${client}-${project}-${environment}-sqs-telemetry`. The root computes the same names and an underscore-only rule name. The historical 28-character naming target is exceeded deliberately to preserve security's established resource contract; AWS service limits apply. Security's IoT trust policy restricts SourceAccount/SourceArn and its identity policy scopes PutItem, SendMessage and precise KMS operations to these resources. No module dependency points back from security to ingest.

The provider supplies seven governance tags. Shared infrastructure stays `FincaID=GLOBAL`; the farm policy uses the exact farm ID. IoT things/certificates do not expose a Terraform `tags` argument in this provider, so farm identity uses the thing's FincaID attribute and the taggable IoT policy. No fictitious IoT or DynamoDB security group is created. [AWS IoT transport security](https://docs.aws.amazon.com/iot/latest/developerguide/transport-security.html) requires TLS; its current default endpoint policy supports TLS 1.2/1.3. Use ATS endpoints and verify the account has not retained a legacy domain policy before real deployment.

## Retention and scope boundary

**TTL is absent on both tables.** There is no 90-day automatic deletion, and this module never accepts a payload-provided expiry attribute. Keep telemetry and threshold versions for at least five calendar years in DynamoDB until a separate, verified archive process can preserve that history. PITR is recovery protection, not a five-year archive or immutable Object Lock retention. The no-expiry choice deliberately costs more than 90-day online storage. IAM governance and an eventual archive/restore test remain necessary to prove production retention.

This small direct-storage pattern fulfills #24's rules-to-store infrastructure boundary; it does **not** implement the complete transactional workflow proposed in #12. DynamoDBv2 uses PutItem with a receipt-specific key: separate MQTT transmissions remain separate rows. This preserves raw history but does not provide business deduplication or conditional conflict detection. Before treating the records as evaluated business telemetry, integrate the approved normalizer/live-replay queues/transactional consumer to enforce event uniqueness, hash conflicts, threshold version selection, durable outbox and application ACK. The five-year retention requirement applies to those finalized business records too. No alert SLA, application ACK, SMS/push, satellite adapter, transport-position API or archival verification is claimed. PUBACK only acknowledges arrival at the rule engine, as [AWS Basic Ingest documents](https://docs.aws.amazon.com/iot/latest/developerguide/iot-basic-ingest.html).

## Use and validation

Use the fully wired [dev environment](../../environments/dev/README.md) or the isolated [sample](sample/README.md). The module exposes policy name, exact publish/config topics, table names/ARNs/streams, error queue URL and rule ARN. Local sources use no `version` argument.

From the repository root, validate through the configured sample and run unit tests in the child module:

```bash
terraform -chdir=modules/ingest/sample init -backend=false -input=false
terraform -chdir=modules/ingest/sample validate
terraform -chdir=modules/ingest init -backend=false -input=false
terraform -chdir=modules/ingest test
```

Do not run standalone `validate` in `modules/ingest`: it declares `aws.project` as a caller-supplied configuration alias. The sample supplies `providers = { aws.project = aws.principal }`; dev supplies `providers = { aws.project = aws }`. Unit tests supply `mock_provider "aws"` with `alias = "project"`. Test mocks are injected by `terraform test`, not by `terraform validate`. No provider configuration belongs inside this reusable module. Validation through the sample needs installed provider schemas but no real CSR, dependency values or AWS credentials. The generic missing-provider diagnostic alone does not establish that any resources exist in state.

All tests use provider mocks and `command = plan`; they do not mutate AWS. They check encryption, retention protection, security role wiring, exact MQTT permissions, trusted SQL identity and rejection of wildcard identities/roles. [VALIDATION.md](../../docs/iac/hu-24-validation.md) records actual execution limits.
