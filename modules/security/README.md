# Security Reference Module - AromaPacifico

This module provisions core security infrastructure for the AromaPacifico platform on AWS in compliance with the AWS Well-Architected Framework and the 26 PC-IAC engineering standards.

## Capabilities

1. Customer Managed Keys (KMS) with automated annual key rotation and lifecycle destruction prevention.
2. Least-privilege IAM roles for platform telemetry ingestion, focus confirmation Lambda, delivery event handlers, and VPC flow logs without wildcard actions on data stores.
3. Security Groups and standalone ingress/egress rules mapping the permanent firewall catalog entries C01 to C20.
4. Network ACLs for private subnets and public query subnets mapping catalog rules N01 to N16.

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.10.0 |
| aws | ~> 6.0 |

## Providers

| Name | Version |
|------|---------|
| aws.project | ~> 6.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| client | Client identifier (e.g. fnc) | string | n/a | yes |
| project | Project name identifier (e.g. aromapacifico) | string | n/a | yes |
| environment | Deployment environment (dev, test, prod) | string | n/a | yes |
| vpc_id | Target VPC ID where security groups and NACLs reside | string | n/a | yes |
| private_subnet_ids | List of private subnet IDs for private NACL association | list(string) | `[]` | no |
| public_subnet_ids | List of public subnet IDs for public query NACL association | list(string) | `[]` | no |
| authorized_private_cidrs | List of authorized internal CIDRs | list(string) | `["10.0.0.0/8"]` | no |
| visitor_cidr | Visitor VLAN CIDR block to deny in N01 | string | `"10.41.5.0/24"` | no |
| inference_model_id | Bedrock foundation model for the leaf diagnosis | string | `"amazon.nova-lite-v1:0"` | no |
| log_authorized_cidr | Logistics clients CIDR for private API access (C04) | string | `"10.41.3.0/24"` | no |
| drone_backup_cidrs | Drone and backup CIDRs for S3 endpoint (C05) | list(string) | `["10.41.20.0/24"]` | no |
| admin_cidr | Admin network CIDR for SSM endpoint (C16, C17) | string | `"10.41.1.0/24"` | no |
| dns_cidr | DNS network CIDR for Route 53 Resolver endpoints (C18, C19) | string | `"10.41.10.0/24"` | no |
| app_cidr | Application tier CIDR for public query return traffic (N14, N15) | string | `"10.50.10.0/24"` | no |
| kms_deletion_window_in_days | KMS key deletion window duration in days | number | `30` | no |
| additional_tags | Map of additional tags to merge | map(string) | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| kms_keys | Map of all KMS keys with key_id, arn, and alias |
| kms_key_data_arn | Dedicated KMS key ARN for agricultural telemetry |
| kms_key_objects_arn | Dedicated KMS key ARN for drone objects and images |
| kms_key_logs_arn | Dedicated KMS key ARN for audit logs and state |
| role_ingest_arn | IAM role ARN for telemetry ingestion |
| role_focus_function_arn | IAM role ARN for focus confirmation Lambda |
| role_delivery_arn | IAM role ARN for sack delivery events |
| role_flow_logs_arn | IAM role ARN for VPC flow logs |
| security_group_ids | Map of all Security Group IDs provisioned |
| nacl_private_id | Private subnets Network ACL identifier |
| nacl_public_id | Public query subnets Network ACL identifier |
| rule_catalog | Complete catalog of permanent firewall rules with parent resource IDs |

## Sample Usage

Refer to the `sample/` directory for consumption patterns complying with PC-IAC-026.


## Ingestion integration contract (#24)

`kms_key_data_arn` and `role_ingest_arn` are the actual outputs used by ingest. The optional `ingest_rule_name` restricts the IoT role's trust to the exact rule and account; null uses the conventional underscore form of `${client}-${project}-${environment}-telemetry`. The ingestion role now allows only telemetry PutItem, reception-queue SendMessage and `kms:Decrypt`, `kms:GenerateDataKey`, `kms:DescribeKey` on the data CMK through DynamoDB/SQS in the same account. It cannot write thresholds. Its output waits for the inline policy. Other role/key/firewall contracts are retained.

The data key policy's existing account delegation allows these scoped identity grants. Broader legacy key administration and other platform-role permissions are not represented as a completed security audit by #24. New tests in `tests/ingest.tftest.hcl` verify ingestion trust and resource/action boundaries without AWS access.
