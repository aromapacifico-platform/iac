# Serverless Function Pattern Module (modules/function)

## AromaPacífico Platform (Federación Nacional de Cafeteros 2026)
### Epic 6 · Part E · Architecture Box E6-06 · Issue #25

---

## Overview

This module implements the canonical serverless pattern for the **Rust Spot Focus Confirmation Function (`FN-CONF-FOCO`)**. It establishes the reference implementation for event-driven inferencing within the AromaPacífico cloud platform, serving as the blueprint for the other three platform functions.

The module provisions:
1. **S3 Confirmation Bucket:** Secure ingest target for drone agricultural imagery with Customer Managed KMS encryption and strict public access blockage.
2. **S3 Event Notification:** Automated event trigger dispatching notifications on `raw-images/focos/` directly to the Lambda function.
3. **Lambda Compute Pattern:** Lightweight Python 3.12 runtime executing ethical PII pre-filtering (Colombian Law 1581 of 2012) and fitosanitary rust spot diagnostic evaluation.
4. **Resilience & Dead Letter Queue (DLQ):** SQS queue with 14-day message retention, KMS CMK encryption, and automated asynchronous event retry configuration (maximum 2 retries before DLQ routing).
5. **Scoped IAM Execution Role:** Adheres strictly to least privilege, implementing the exact 3 functional permissions (S3 read, DynamoDB write to expedientes, Rekognition inference) plus CloudWatch logs and DLQ publishing.
6. **Zero Trust Fumigation Invariant:** Under no circumstance does this module possess privileges or code logic to authorize fumigation orders.

---

## Architecture Pattern

```
[Drone Upload] --> S3 Confirmation Bucket (raw-images/focos/)
                         |
                         v (s3:ObjectCreated:*)
                 Lambda Pattern (FN-CONF-FOCO)
                   /           |            \
                  v            v             v
          [Rekognition]   [DynamoDB]     [SQS DLQ]
          (Anti-PII)   (Expedientes)    (2 Retries Fail)
```

---

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| client | Client identifier (max 8 chars) | `string` | `"fnc"` | no |
| project | Project name identifier (max 16 chars) | `string` | `"aromapacifico"` | no |
| environment | Target deployment environment | `string` | `"desarrollo"` | no |
| aws_region | AWS target deployment region | `string` | `"us-east-1"` | no |
| name_prefix | Optional custom physical naming prefix | `string` | `""` | no |
| expedientes_table_name | DynamoDB table name for fitosanitary expedientes | `string` | `"fnc-aromapacifico-dev-dynamo-expedientes"` | no |
| kms_key_objects_arn | KMS Key ARN for S3 objects encryption | `string` | n/a | yes |
| kms_key_data_arn | KMS Key ARN for DynamoDB data and SQS DLQ encryption | `string` | n/a | yes |
| kms_key_logs_arn | Optional KMS Key ARN for CloudWatch Log Group | `string` | `""` | no |
| notification_filter_prefix | S3 object key prefix triggering Lambda | `string` | `"raw-images/focos/"` | no |
| notification_filter_suffix | S3 object key suffix triggering Lambda | `string` | `".jpg"` | no |
| rekognition_min_confidence | Minimum confidence threshold for Rekognition | `number` | `50.0` | no |
| lambda_memory_size | Memory size in megabytes | `number` | `512` | no |
| lambda_timeout | Execution timeout in seconds | `number` | `60` | no |
| log_retention_in_days | Log retention window in days | `number` | `30` | no |
| create_iam_role | Whether to create dedicated execution role | `bool` | `true` | no |
| custom_iam_role_arn | External IAM role ARN if create_iam_role is false | `string` | `""` | no |
| subnet_ids | Private subnet IDs for Lambda VPC integration | `list(string)` | `[]` | no |
| security_group_ids | Security group IDs for Lambda VPC integration | `list(string)` | `[]` | no |
| additional_tags | Map of additional tags to merge | `map(string)` | `{}` | no |

---

## Outputs

| Name | Description |
|------|-------------|
| s3_bucket_id | Identifier of the created confirmation S3 bucket |
| s3_bucket_arn | ARN of the created confirmation S3 bucket |
| lambda_function_name | Name of the provisioned Lambda function |
| lambda_function_arn | ARN of the provisioned Lambda function |
| sqs_dlq_id | URL/Identifier of the Dead Letter Queue |
| sqs_dlq_arn | ARN of the Dead Letter Queue |
| cloudwatch_log_group_name | Name of the CloudWatch Log Group |
| cloudwatch_log_group_arn | ARN of the CloudWatch Log Group |
| iam_role_arn | Effective IAM role ARN attached to the function |
| retry_attempts | Maximum retry attempts before routing to DLQ |

---

## Governance & Rules Compliance

- **PC-IAC-001:** Standard 10-file root module layout and 7-file `sample/` test fixture.
- **PC-IAC-002:** All variables declare strict `type`, `description`, and `validation` blocks.
- **PC-IAC-003:** Naming follows `${client}-${project}-${environment}-${type}-${key}` (<= 28 chars).
- **PC-IAC-004:** Two-layer tagging model combining provider defaults with resource `Name` tags.
- **PC-IAC-005:** Module consumes provider via `configuration_aliases = [aws.project]`.
- **PC-IAC-006:** Pinned to Terraform `>= 1.10.0` and AWS provider `~> 5.0`.
- **PC-IAC-007:** Explicit description provided for all outputs.
- **PC-IAC-008:** Zero backend blocks declared inside the module.
- **PC-IAC-010:** S3 confirmation bucket protected with `prevent_destroy = true`.
- **PC-IAC-020:** Enforces SSE-KMS at rest, TLS 1.2+ in transit, and S3 public access block.
- **PC-IAC-022:** Workload boundary respected: does not create VPC or Security Groups.
- **PC-IAC-026:** Decoupled `sample/` consuming pure variables transformed in `locals.tf`.
