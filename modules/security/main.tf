# ==============================================================================
# Customer Managed Keys (KMS) - CMK with Annual Rotation (PC-IAC-020, PC-IAC-010)
# ==============================================================================

resource "aws_kms_key" "this" {
  provider = aws.project

  for_each                = local.kms_keys
  description             = each.value.description
  deletion_window_in_days = var.kms_deletion_window_in_days
  enable_key_rotation     = true

  policy = data.aws_iam_policy_document.kms_key_policy[each.key].json

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-kms-${each.key}"
      Role = each.key
    }
  )

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_kms_alias" "this" {
  provider = aws.project

  for_each      = local.kms_keys
  name          = each.value.alias
  target_key_id = aws_kms_key.this[each.key].key_id
}

data "aws_iam_policy_document" "kms_key_policy" {
  for_each = local.kms_keys

  statement {
    sid       = "EnableRootAccountAdministration"
    effect    = "Allow"
    actions   = ["kms:*"]
    resources = ["*"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${local.account_id}:root"]
    }
  }

  statement {
    sid    = "AllowServiceUsageUnderAccountConditions"
    effect = "Allow"
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey"
    ]
    resources = ["*"]

    principals {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::${local.account_id}:root"
      ]
    }

    condition {
      test     = "StringEquals"
      variable = "kms:CallerAccount"
      values   = [local.account_id]
    }
  }
}

# ==============================================================================
# Platform IAM Roles & Zero-Wildcard Policies (PC-IAC-020, Issue #4, Issue #23)
# ==============================================================================

# 1. Ingest Role (IoT Core Rule Action)
resource "aws_iam_role" "ingest" {
  provider = aws.project

  name        = "${local.name_prefix}-role-ingest"
  description = "Role for AWS IoT Core to publish telemetry into DynamoDB and SQS"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "iot.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-role-ingest"
    }
  )
}

resource "aws_iam_role_policy" "ingest" {
  provider = aws.project

  name = "${local.name_prefix}-pol-ingest"
  role = aws_iam_role.ingest.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "DynamoDBTelemetryPutItem"
        Effect = "Allow"
        Action = [
          "dynamodb:PutItem",
          "dynamodb:UpdateItem"
        ]
        Resource = "arn:aws:dynamodb:${local.aws_region}:${local.account_id}:table/${local.name_prefix}-dynamo-telemetry"
      },
      {
        Sid    = "SQSTelemetrySendMessage"
        Effect = "Allow"
        Action = [
          "sqs:SendMessage"
        ]
        Resource = "arn:aws:sqs:${local.aws_region}:${local.account_id}:${local.name_prefix}-sqs-telemetry"
      },
      {
        Sid    = "KMSDataKeyEncryption"
        Effect = "Allow"
        Action = [
          "kms:Encrypt",
          "kms:GenerateDataKey*"
        ]
        Resource = aws_kms_key.this["data"].arn
      }
    ]
  })
}

# 2. Focus Confirmation Function Role (Lambda)
resource "aws_iam_role" "focus_function" {
  provider = aws.project

  name        = "${local.name_prefix}-role-focus-func"
  description = "Role for focus confirmation Lambda with exact least privilege"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-role-focus-func"
    }
  )
}

resource "aws_iam_role_policy" "focus_function" {
  provider = aws.project

  name = "${local.name_prefix}-pol-focus-func"
  role = aws_iam_role.focus_function.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "S3ReadFocusObject"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion"
        ]
        Resource = "arn:aws:s3:::${var.client}-${var.project}-${var.environment}-focus/*"
      },
      {
        Sid    = "RekognitionManagedInference"
        Effect = "Allow"
        Action = [
          "rekognition:DetectLabels",
          "rekognition:DetectCustomLabels"
        ]
        Resource = "*"
      },
      {
        Sid    = "DynamoDBWriteFocusResult"
        Effect = "Allow"
        Action = [
          "dynamodb:PutItem",
          "dynamodb:UpdateItem"
        ]
        Resource = "arn:aws:dynamodb:${local.aws_region}:${local.account_id}:table/${local.name_prefix}-dynamo-expedientes"
      },
      {
        Sid    = "KMSDecryptObjectsAndData"
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey*"
        ]
        Resource = [
          aws_kms_key.this["objects"].arn,
          aws_kms_key.this["data"].arn
        ]
      },
      {
        Sid    = "SQSSendDeadLetterQueue"
        Effect = "Allow"
        Action = [
          "sqs:SendMessage"
        ]
        Resource = "arn:aws:sqs:${local.aws_region}:${local.account_id}:${local.name_prefix}-sqs-focus-dlq"
      },
      {
        Sid    = "CloudWatchLogsWrite"
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:${local.aws_region}:${local.account_id}:log-group:/aws/lambda/${local.name_prefix}-func-focus:*"
      },
      {
        Sid    = "VPCAccessExecution"
        Effect = "Allow"
        Action = [
          "ec2:CreateNetworkInterface",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DeleteNetworkInterface"
        ]
        Resource = "*"
      }
    ]
  })
}

# 3. Delivery / Sack Events Role
resource "aws_iam_role" "delivery" {
  provider = aws.project

  name        = "${local.name_prefix}-role-delivery"
  description = "Role for port delivery and sack transaction events"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-role-delivery"
    }
  )
}

resource "aws_iam_role_policy" "delivery" {
  provider = aws.project

  name = "${local.name_prefix}-pol-delivery"
  role = aws_iam_role.delivery.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "DynamoDBSackLedgerWrite"
        Effect = "Allow"
        Action = [
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
          "dynamodb:GetItem"
        ]
        Resource = "arn:aws:dynamodb:${local.aws_region}:${local.account_id}:table/${local.name_prefix}-dynamo-sacos"
      },
      {
        Sid    = "KMSDataKeyOperations"
        Effect = "Allow"
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:GenerateDataKey*"
        ]
        Resource = aws_kms_key.this["data"].arn
      },
      {
        Sid    = "CloudWatchLogsDelivery"
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:${local.aws_region}:${local.account_id}:log-group:/aws/lambda/${local.name_prefix}-func-delivery:*"
      }
    ]
  })
}

# 4. VPC Flow Logs Role
resource "aws_iam_role" "flow_logs" {
  provider = aws.project

  name        = "${local.name_prefix}-role-flow-logs"
  description = "Role for VPC Flow Logs publication to CloudWatch Logs"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "vpc-flow-logs.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-role-flow-logs"
    }
  )
}

resource "aws_iam_role_policy" "flow_logs" {
  provider = aws.project

  name = "${local.name_prefix}-pol-flow-logs"
  role = aws_iam_role.flow_logs.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "CloudWatchFlowLogsPublish"
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ]
        Resource = "arn:aws:logs:${local.aws_region}:${local.account_id}:log-group:/aws/vpc-flow-logs/${local.name_prefix}:*"
      }
    ]
  })
}

# ==============================================================================
# Security Groups - Permanent Firewall Catalog (PC-IAC-020, PC-IAC-022, Issue #9)
# ==============================================================================

# SG-ALB-CONSULTA
resource "aws_security_group" "alb_query" {
  provider = aws.project

  name        = "${local.name_prefix}-sg-alb-query"
  description = "Security Group for Public Sack Query Application Load Balancer"
  vpc_id      = var.vpc_id

  tags = merge(
    local.common_tags,
    {
      Name    = "${local.name_prefix}-sg-alb-query"
      Catalog = "C01-C02"
    }
  )
}

# SG-CONSULTA
resource "aws_security_group" "query" {
  provider = aws.project

  name        = "${local.name_prefix}-sg-query"
  description = "Security Group for Backend Query Microservice"
  vpc_id      = var.vpc_id

  tags = merge(
    local.common_tags,
    {
      Name    = "${local.name_prefix}-sg-query"
      Catalog = "C03-C20"
    }
  )
}

# SG-VPCE-API
resource "aws_security_group" "vpce_api" {
  provider = aws.project

  name        = "${local.name_prefix}-sg-vpce-api"
  description = "Security Group for Private API Gateway Interface Endpoint"
  vpc_id      = var.vpc_id

  tags = merge(
    local.common_tags,
    {
      Name    = "${local.name_prefix}-sg-vpce-api"
      Catalog = "C04"
    }
  )
}

# SG-VPCE-S3
resource "aws_security_group" "vpce_s3" {
  provider = aws.project

  name        = "${local.name_prefix}-sg-vpce-s3"
  description = "Security Group for S3 PrivateLink Interface Endpoint from collection centers"
  vpc_id      = var.vpc_id

  tags = merge(
    local.common_tags,
    {
      Name    = "${local.name_prefix}-sg-vpce-s3"
      Catalog = "C05"
    }
  )
}

# SG-INGESTA
resource "aws_security_group" "ingest" {
  provider = aws.project

  name        = "${local.name_prefix}-sg-ingest"
  description = "Security Group for Telemetry Ingestion Services and ENIs"
  vpc_id      = var.vpc_id

  tags = merge(
    local.common_tags,
    {
      Name    = "${local.name_prefix}-sg-ingest"
      Catalog = "C06-C07"
    }
  )
}

# SG-FUNCION
resource "aws_security_group" "function" {
  provider = aws.project

  name        = "${local.name_prefix}-sg-function"
  description = "Security Group for Focus Confirmation Lambda ENIs"
  vpc_id      = var.vpc_id

  tags = merge(
    local.common_tags,
    {
      Name    = "${local.name_prefix}-sg-function"
      Catalog = "C08-C10"
    }
  )
}

# SG-VPCE-REKOG
resource "aws_security_group" "vpce_rekog" {
  provider = aws.project

  name        = "${local.name_prefix}-sg-vpce-rekog"
  description = "Security Group for AWS Rekognition Interface Endpoint"
  vpc_id      = var.vpc_id

  tags = merge(
    local.common_tags,
    {
      Name    = "${local.name_prefix}-sg-vpce-rekog"
      Catalog = "C11"
    }
  )
}

# SG-CLIENTES-LOG
resource "aws_security_group" "clients_log" {
  provider = aws.project

  name        = "${local.name_prefix}-sg-clients-log"
  description = "Security Group for Platform Services publishing CloudWatch Logs"
  vpc_id      = var.vpc_id

  tags = merge(
    local.common_tags,
    {
      Name    = "${local.name_prefix}-sg-clients-log"
      Catalog = "C12"
    }
  )
}

# SG-VPCE-LOGS
resource "aws_security_group" "vpce_logs" {
  provider = aws.project

  name        = "${local.name_prefix}-sg-vpce-logs"
  description = "Security Group for CloudWatch Logs Interface Endpoint"
  vpc_id      = var.vpc_id

  tags = merge(
    local.common_tags,
    {
      Name    = "${local.name_prefix}-sg-vpce-logs"
      Catalog = "C13"
    }
  )
}

# SG-CLIENTES-KMS
resource "aws_security_group" "clients_kms" {
  provider = aws.project

  name        = "${local.name_prefix}-sg-clients-kms"
  description = "Security Group for Platform Services invoking AWS KMS"
  vpc_id      = var.vpc_id

  tags = merge(
    local.common_tags,
    {
      Name    = "${local.name_prefix}-sg-clients-kms"
      Catalog = "C14"
    }
  )
}

# SG-VPCE-KMS
resource "aws_security_group" "vpce_kms" {
  provider = aws.project

  name        = "${local.name_prefix}-sg-vpce-kms"
  description = "Security Group for AWS KMS Interface Endpoint"
  vpc_id      = var.vpc_id

  tags = merge(
    local.common_tags,
    {
      Name    = "${local.name_prefix}-sg-vpce-kms"
      Catalog = "C15"
    }
  )
}

# SG-ADMIN
resource "aws_security_group" "admin" {
  provider = aws.project

  name        = "${local.name_prefix}-sg-admin"
  description = "Security Group for Administration Bastions and Runners"
  vpc_id      = var.vpc_id

  tags = merge(
    local.common_tags,
    {
      Name    = "${local.name_prefix}-sg-admin"
      Catalog = "C16"
    }
  )
}

# SG-VPCE-SSM
resource "aws_security_group" "vpce_ssm" {
  provider = aws.project

  name        = "${local.name_prefix}-sg-vpce-ssm"
  description = "Security Group for AWS SSM Interface Endpoint"
  vpc_id      = var.vpc_id

  tags = merge(
    local.common_tags,
    {
      Name    = "${local.name_prefix}-sg-vpce-ssm"
      Catalog = "C17"
    }
  )
}

# SG-RESOLVER-IN
resource "aws_security_group" "resolver_in" {
  provider = aws.project

  name        = "${local.name_prefix}-sg-resolver-in"
  description = "Security Group for Route 53 Resolver Inbound Endpoint"
  vpc_id      = var.vpc_id

  tags = merge(
    local.common_tags,
    {
      Name    = "${local.name_prefix}-sg-resolver-in"
      Catalog = "C18"
    }
  )
}

# SG-RESOLVER-OUT
resource "aws_security_group" "resolver_out" {
  provider = aws.project

  name        = "${local.name_prefix}-sg-resolver-out"
  description = "Security Group for Route 53 Resolver Outbound Endpoint"
  vpc_id      = var.vpc_id

  tags = merge(
    local.common_tags,
    {
      Name    = "${local.name_prefix}-sg-resolver-out"
      Catalog = "C19"
    }
  )
}

# ==============================================================================
# Standalone Ingress / Egress Rules (Rule Catalog C01-C20, Invariants C21, C22)
# ==============================================================================

# Rule C01: SG-ALB-CONSULTA Ingress from 0.0.0.0/0 on 443
resource "aws_vpc_security_group_ingress_rule" "c01" {
  provider          = aws.project
  security_group_id = aws_security_group.alb_query.id
  description       = "C01: Public HTTPS ingress to sack query ALB"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = "0.0.0.0/0"
}

# Rule C02: SG-ALB-CONSULTA Egress to SG-CONSULTA on 443
resource "aws_vpc_security_group_egress_rule" "c02" {
  provider                     = aws.project
  security_group_id            = aws_security_group.alb_query.id
  description                  = "C02: ALB forwarding to backend query service"
  ip_protocol                  = "tcp"
  from_port                    = 443
  to_port                      = 443
  referenced_security_group_id = aws_security_group.query.id
}

# Rule C03: SG-CONSULTA Ingress from SG-ALB-CONSULTA on 443
resource "aws_vpc_security_group_ingress_rule" "c03" {
  provider                     = aws.project
  security_group_id            = aws_security_group.query.id
  description                  = "C03: Backend query service receiving from ALB"
  ip_protocol                  = "tcp"
  from_port                    = 443
  to_port                      = 443
  referenced_security_group_id = aws_security_group.alb_query.id
}

# Rule C04: SG-VPCE-API Ingress from LOG-AUT-CIDR on 443
resource "aws_vpc_security_group_ingress_rule" "c04" {
  provider          = aws.project
  security_group_id = aws_security_group.vpce_api.id
  description       = "C04: Logistics reception clients accessing private API endpoint"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = var.log_authorized_cidr
}

# Rule C05: SG-VPCE-S3 Ingress from Drone / Backup CIDRs on 443
resource "aws_vpc_security_group_ingress_rule" "c05" {
  provider = aws.project

  for_each          = toset(var.drone_backup_cidrs)
  security_group_id = aws_security_group.vpce_s3.id
  description       = "C05: Collection center drone and backup sync to S3 interface endpoint"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = each.value
}

# Rule C10: SG-FUNCION Egress to SG-VPCE-REKOG on 443
resource "aws_vpc_security_group_egress_rule" "c10" {
  provider                     = aws.project
  security_group_id            = aws_security_group.function.id
  description                  = "C10: Focus function calling Rekognition interface endpoint"
  ip_protocol                  = "tcp"
  from_port                    = 443
  to_port                      = 443
  referenced_security_group_id = aws_security_group.vpce_rekog.id
}

# Rule C11: SG-VPCE-REKOG Ingress from SG-FUNCION on 443
resource "aws_vpc_security_group_ingress_rule" "c11" {
  provider                     = aws.project
  security_group_id            = aws_security_group.vpce_rekog.id
  description                  = "C11: Rekognition interface endpoint receiving from focus function"
  ip_protocol                  = "tcp"
  from_port                    = 443
  to_port                      = 443
  referenced_security_group_id = aws_security_group.function.id
}

# Rule C12: SG-CLIENTES-LOG Egress to SG-VPCE-LOGS on 443
resource "aws_vpc_security_group_egress_rule" "c12" {
  provider                     = aws.project
  security_group_id            = aws_security_group.clients_log.id
  description                  = "C12: Workload clients sending traces to CloudWatch Logs endpoint"
  ip_protocol                  = "tcp"
  from_port                    = 443
  to_port                      = 443
  referenced_security_group_id = aws_security_group.vpce_logs.id
}

# Rule C13: SG-VPCE-LOGS Ingress from SG-CLIENTES-LOG on 443
resource "aws_vpc_security_group_ingress_rule" "c13" {
  provider                     = aws.project
  security_group_id            = aws_security_group.vpce_logs.id
  description                  = "C13: CloudWatch Logs endpoint receiving from authorized clients"
  ip_protocol                  = "tcp"
  from_port                    = 443
  to_port                      = 443
  referenced_security_group_id = aws_security_group.clients_log.id
}

# Rule C14: SG-CLIENTES-KMS Egress to SG-VPCE-KMS on 443
resource "aws_vpc_security_group_egress_rule" "c14" {
  provider                     = aws.project
  security_group_id            = aws_security_group.clients_kms.id
  description                  = "C14: Workload clients invoking KMS operations via private endpoint"
  ip_protocol                  = "tcp"
  from_port                    = 443
  to_port                      = 443
  referenced_security_group_id = aws_security_group.vpce_kms.id
}

# Rule C15: SG-VPCE-KMS Ingress from SG-CLIENTES-KMS on 443
resource "aws_vpc_security_group_ingress_rule" "c15" {
  provider                     = aws.project
  security_group_id            = aws_security_group.vpce_kms.id
  description                  = "C15: KMS interface endpoint receiving from authorized workload clients"
  ip_protocol                  = "tcp"
  from_port                    = 443
  to_port                      = 443
  referenced_security_group_id = aws_security_group.clients_kms.id
}

# Rule C16: SG-ADMIN Egress to SG-VPCE-SSM on 443
resource "aws_vpc_security_group_egress_rule" "c16" {
  provider                     = aws.project
  security_group_id            = aws_security_group.admin.id
  description                  = "C16: Admin instance connecting to AWS SSM endpoint"
  ip_protocol                  = "tcp"
  from_port                    = 443
  to_port                      = 443
  referenced_security_group_id = aws_security_group.vpce_ssm.id
}

# Rule C17: SG-VPCE-SSM Ingress from ADMIN-CIDR on 443
resource "aws_vpc_security_group_ingress_rule" "c17" {
  provider          = aws.project
  security_group_id = aws_security_group.vpce_ssm.id
  description       = "C17: SSM endpoint receiving from authorized admin network"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = var.admin_cidr
}

# Rule C18: SG-RESOLVER-IN Ingress from DNS-CIDR on 53 TCP/UDP
resource "aws_vpc_security_group_ingress_rule" "c18_tcp" {
  provider          = aws.project
  security_group_id = aws_security_group.resolver_in.id
  description       = "C18: Route 53 Resolver Inbound TCP from local DNS forwarders"
  ip_protocol       = "tcp"
  from_port         = 53
  to_port           = 53
  cidr_ipv4         = var.dns_cidr
}

resource "aws_vpc_security_group_ingress_rule" "c18_udp" {
  provider          = aws.project
  security_group_id = aws_security_group.resolver_in.id
  description       = "C18: Route 53 Resolver Inbound UDP from local DNS forwarders"
  ip_protocol       = "udp"
  from_port         = 53
  to_port           = 53
  cidr_ipv4         = var.dns_cidr
}

# Rule C19: SG-RESOLVER-OUT Egress to DNS-CIDR on 53 TCP/UDP
resource "aws_vpc_security_group_egress_rule" "c19_tcp" {
  provider          = aws.project
  security_group_id = aws_security_group.resolver_out.id
  description       = "C19: Route 53 Resolver Outbound TCP to local DNS forwarders"
  ip_protocol       = "tcp"
  from_port         = 53
  to_port           = 53
  cidr_ipv4         = var.dns_cidr
}

resource "aws_vpc_security_group_egress_rule" "c19_udp" {
  provider          = aws.project
  security_group_id = aws_security_group.resolver_out.id
  description       = "C19: Route 53 Resolver Outbound UDP to local DNS forwarders"
  ip_protocol       = "udp"
  from_port         = 53
  to_port           = 53
  cidr_ipv4         = var.dns_cidr
}

# ==============================================================================
# Network ACLs - Permanent Subnet Policy Catalog (Rules N01-N16)
# ==============================================================================

# Private Subnets Network ACL
resource "aws_network_acl" "private" {
  provider = aws.project

  vpc_id     = var.vpc_id
  subnet_ids = var.private_subnet_ids

  # Rule N01: Deny VIS-CIDR (10.X.5.0/24)
  ingress {
    rule_no    = 10
    protocol   = "-1"
    action     = "deny"
    cidr_block = var.visitor_cidr
    from_port  = 0
    to_port    = 0
  }

  # Rule N02: Allow PRIV-AUT HTTPS Ingress
  ingress {
    rule_no    = 100
    protocol   = "tcp"
    action     = "allow"
    cidr_block = var.authorized_private_cidrs[0]
    from_port  = 443
    to_port    = 443
  }

  # Rule N04: Allow PRIV-AUT DNS TCP Ingress
  ingress {
    rule_no    = 110
    protocol   = "tcp"
    action     = "allow"
    cidr_block = var.authorized_private_cidrs[0]
    from_port  = 53
    to_port    = 53
  }

  # Rule N05: Allow PRIV-AUT DNS UDP Ingress
  ingress {
    rule_no    = 120
    protocol   = "udp"
    action     = "allow"
    cidr_block = var.authorized_private_cidrs[0]
    from_port  = 53
    to_port    = 53
  }

  # Rule N08: Allow Ephemeral Return Ports TCP Ingress
  ingress {
    rule_no    = 130
    protocol   = "tcp"
    action     = "allow"
    cidr_block = var.authorized_private_cidrs[0]
    from_port  = 1024
    to_port    = 65535
  }

  # Rule N10: Allow Ephemeral Return Ports UDP Ingress
  ingress {
    rule_no    = 140
    protocol   = "udp"
    action     = "allow"
    cidr_block = var.authorized_private_cidrs[0]
    from_port  = 1024
    to_port    = 65535
  }

  # Rule N03: Allow PRIV-AUT HTTPS Egress
  egress {
    rule_no    = 100
    protocol   = "tcp"
    action     = "allow"
    cidr_block = var.authorized_private_cidrs[0]
    from_port  = 443
    to_port    = 443
  }

  # Rule N06: Allow PRIV-AUT DNS TCP Egress
  egress {
    rule_no    = 110
    protocol   = "tcp"
    action     = "allow"
    cidr_block = var.authorized_private_cidrs[0]
    from_port  = 53
    to_port    = 53
  }

  # Rule N07: Allow PRIV-AUT DNS UDP Egress
  egress {
    rule_no    = 120
    protocol   = "udp"
    action     = "allow"
    cidr_block = var.authorized_private_cidrs[0]
    from_port  = 53
    to_port    = 53
  }

  # Rule N09: Allow PRIV-AUT Ephemeral Ports TCP Egress
  egress {
    rule_no    = 130
    protocol   = "tcp"
    action     = "allow"
    cidr_block = var.authorized_private_cidrs[0]
    from_port  = 1024
    to_port    = 65535
  }

  # Rule N11: Allow PRIV-AUT Ephemeral Ports UDP Egress
  egress {
    rule_no    = 140
    protocol   = "udp"
    action     = "allow"
    cidr_block = var.authorized_private_cidrs[0]
    from_port  = 1024
    to_port    = 65535
  }

  tags = merge(
    local.common_tags,
    {
      Name    = "${local.name_prefix}-nacl-private"
      Catalog = "N01-N11,N16"
    }
  )
}

# Public Query Subnets Network ACL
resource "aws_network_acl" "public" {
  provider = aws.project

  vpc_id     = var.vpc_id
  subnet_ids = var.public_subnet_ids

  # Rule N12: Allow 0.0.0.0/0 HTTPS Ingress
  ingress {
    rule_no    = 100
    protocol   = "tcp"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 443
    to_port    = 443
  }

  # Rule N15: Allow Return Traffic from APP-CIDR Ingress
  ingress {
    rule_no    = 110
    protocol   = "tcp"
    action     = "allow"
    cidr_block = var.app_cidr
    from_port  = 1024
    to_port    = 65535
  }

  # Rule N13: Allow Ephemeral Return to Internet Egress
  egress {
    rule_no    = 100
    protocol   = "tcp"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 1024
    to_port    = 65535
  }

  # Rule N14: Allow Forwarding to APP-CIDR HTTPS Egress
  egress {
    rule_no    = 110
    protocol   = "tcp"
    action     = "allow"
    cidr_block = var.app_cidr
    from_port  = 443
    to_port    = 443
  }

  tags = merge(
    local.common_tags,
    {
      Name    = "${local.name_prefix}-nacl-public"
      Catalog = "N12-N16"
    }
  )
}

