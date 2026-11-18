# Changelog

All notable changes to `modules/network` will be documented in this file.

## [1.1.0] - 2026-11-17
- Standardized module structure to 10 root files and `sample/` fixture (`PC-IAC-001`, `PC-IAC-026`).
- Added `configuration_aliases = [aws.project]` (`PC-IAC-005`) and `additional_tags` Layer 2 merging (`PC-IAC-004`).
- Consolidated `locals.tf` into a single `locals` block (`PC-IAC-012`).
- Added `validation` on `hybrid/variables.tf` `name_prefix` (`PC-IAC-002`) and `prevent_destroy = true` on hybrid CGW/VPN (`PC-IAC-010`).

## [1.0.0] - 2026-11-08
- Initial VPC, 14 multi-AZ subnets, Gateway Endpoints, S3 Interface Endpoint, and TGW/VPN hybrid module implementation (Issue #22).
