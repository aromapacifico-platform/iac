# Changelog - Security Module

All notable changes to the security reference module will be documented in this file.

## [1.1.0] - 2026-11-11
### Removed
- Retired rule C19 (`aws_vpc_security_group_egress_rule.c19_tcp` and `c19_udp`) and Security Group `resolver_out` per FinOps Decision 3 (Issue #31).
- Removed `sg_egress["C19"]` from `rule_catalog` output contract and `resolver_out` from `security_group_ids`.

## [1.0.0] - 2026-11-10
### Added
- Customer Managed KMS Keys for data, objects, and audit logs with annual rotation and deletion protection.
- Platform IAM roles for telemetry ingest, focus confirmation function, sack event delivery, and flow logs.
- Security Groups and rules mapping the permanent firewall policy catalog (C01-C20, C21, C22).
- Network ACLs with rule-by-rule mapping of the permanent subnet policy catalog (N01-N16).
- Contract output `rule_catalog` exposing all permanent firewall rules mapped to their parent resource IDs (`parent_id`).
- Full compliance with PC-IAC-001 through PC-IAC-026.

