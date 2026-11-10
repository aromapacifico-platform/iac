# Changelog - Function Pattern Module

All notable changes to the focus confirmation serverless function reference module will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-11-10
### Added
- S3 confirmation bucket with KMS CMK encryption, object versioning, and strict block public access.
- SQS Dead Letter Queue (DLQ) with 14-day retention, KMS encryption, and Lambda asynchronous failure routing.
- Python 3.12 serverless function pattern (`FN-CONF-FOCO`) implementing PII verification and rust spot detection.
- Asynchronous invocation configuration with 2 retries and Dead Letter Queue target destination.
- S3 event trigger notification on prefix `raw-images/focos/` with invocation permission.
- Scoped IAM execution role granting the exact 3 required permissions (S3 read, DynamoDB write to expedientes, Rekognition inference) plus CloudWatch logs and SQS DLQ.
- Explicit invariant preventing the Lambda role from modifying or authorizing fumigation orders.
- Comprehensive fixture in `sample/` following the PC-IAC-026 transformation pattern.

