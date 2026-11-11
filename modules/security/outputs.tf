output "kms_keys" {
  description = "Map of all customer managed KMS keys created with their key_id, arn and alias."
  value = {
    for k, v in aws_kms_key.this : k => {
      key_id = v.key_id
      arn    = v.arn
      alias  = aws_kms_alias.this[k].name
    }
  }
}

output "kms_key_data_arn" {
  description = "KMS Customer Managed Key ARN for agricultural telemetry and sack master ledger."
  value       = aws_kms_key.this["data"].arn
}

output "kms_key_objects_arn" {
  description = "KMS Customer Managed Key ARN for drone flight binaries, images and inference objects."
  value       = aws_kms_key.this["objects"].arn
}

output "kms_key_logs_arn" {
  description = "KMS Customer Managed Key ARN for CloudWatch audit traces, state locking and flow logs."
  value       = aws_kms_key.this["logs"].arn
}

output "role_ingest_arn" {
  description = "IAM Role ARN for AWS IoT Core to publish telemetry into DynamoDB and SQS."
  value       = aws_iam_role.ingest.arn
  depends_on  = [aws_iam_role_policy.ingest]
}

output "role_focus_function_arn" {
  description = "IAM Role ARN for focus confirmation Lambda execution."
  value       = aws_iam_role.focus_function.arn
}

output "role_delivery_arn" {
  description = "IAM Role ARN for port delivery and sack transaction events."
  value       = aws_iam_role.delivery.arn
}

output "role_flow_logs_arn" {
  description = "IAM Role ARN for VPC Flow Logs publication to CloudWatch Logs."
  value       = aws_iam_role.flow_logs.arn
}

output "security_group_ids" {
  description = "Map of all provisioned Security Group IDs keyed by role."
  value = {
    alb_query    = aws_security_group.alb_query.id
    query        = aws_security_group.query.id
    vpce_api     = aws_security_group.vpce_api.id
    vpce_s3      = aws_security_group.vpce_s3.id
    ingest       = aws_security_group.ingest.id
    function     = aws_security_group.function.id
    vpce_rekog   = aws_security_group.vpce_rekog.id
    clients_log  = aws_security_group.clients_log.id
    vpce_logs    = aws_security_group.vpce_logs.id
    clients_kms  = aws_security_group.clients_kms.id
    vpce_kms     = aws_security_group.vpce_kms.id
    admin        = aws_security_group.admin.id
    vpce_ssm     = aws_security_group.vpce_ssm.id
    resolver_in  = aws_security_group.resolver_in.id
    resolver_out = aws_security_group.resolver_out.id
  }
}

output "nacl_private_id" {
  description = "Network ACL ID protecting private environment subnets."
  value       = aws_network_acl.private.id
}

output "nacl_public_id" {
  description = "Network ACL ID protecting public query subnets."
  value       = aws_network_acl.public.id
}

output "rule_catalog" {
  description = "Catalog of permanent firewall rules mapped with contract keys, parent resource IDs and metadata."
  value = {
    "sg_ingress[\"C01\"]" = {
      id          = "C01"
      control     = "SG-IN"
      parent_id   = aws_security_group.alb_query.id
      source      = "0.0.0.0/0"
      destination = "SG-ALB-CONSULTA"
      protocol    = "tcp"
      from_port   = 443
      to_port     = 443
      action      = "Permitir"
      permanence  = "P"
      component   = "Consulta"
      owner       = "devops-fnc"
    }
    "sg_egress[\"C02\"]" = {
      id          = "C02"
      control     = "SG-OUT"
      parent_id   = aws_security_group.alb_query.id
      source      = "SG-ALB-CONSULTA"
      destination = "SG-CONSULTA"
      protocol    = "tcp"
      from_port   = 443
      to_port     = 443
      action      = "Permitir"
      permanence  = "P"
      component   = "Consulta"
      owner       = "devops-fnc"
    }
    "sg_ingress[\"C03\"]" = {
      id          = "C03"
      control     = "SG-IN"
      parent_id   = aws_security_group.query.id
      source      = "SG-ALB-CONSULTA"
      destination = "SG-CONSULTA"
      protocol    = "tcp"
      from_port   = 443
      to_port     = 443
      action      = "Permitir"
      permanence  = "P"
      component   = "Consulta"
      owner       = "devops-fnc"
    }
    "sg_ingress[\"C04\"]" = {
      id          = "C04"
      control     = "SG-IN"
      parent_id   = aws_security_group.vpce_api.id
      source      = var.log_authorized_cidr
      destination = "SG-VPCE-API"
      protocol    = "tcp"
      from_port   = 443
      to_port     = 443
      action      = "Permitir"
      permanence  = "P"
      component   = "Privado"
      owner       = "devops-fnc"
    }
    "sg_ingress[\"C05\"]" = {
      id          = "C05"
      control     = "SG-IN"
      parent_id   = aws_security_group.vpce_s3.id
      source      = join(", ", var.drone_backup_cidrs)
      destination = "SG-VPCE-S3"
      protocol    = "tcp"
      from_port   = 443
      to_port     = 443
      action      = "Permitir"
      permanence  = "P"
      component   = "Objetos"
      owner       = "devops-fnc"
    }
    "sg_egress[\"C06\"]" = {
      id          = "C06"
      control     = "SG-OUT"
      parent_id   = aws_security_group.ingest.id
      source      = "SG-INGESTA"
      destination = "PL-DDB"
      protocol    = "tcp"
      from_port   = 443
      to_port     = 443
      action      = "Permitir"
      permanence  = "P"
      component   = "Patron"
      owner       = "devops-fnc"
    }
    "sg_egress[\"C07\"]" = {
      id          = "C07"
      control     = "SG-OUT"
      parent_id   = aws_security_group.ingest.id
      source      = "SG-INGESTA"
      destination = "PL-S3"
      protocol    = "tcp"
      from_port   = 443
      to_port     = 443
      action      = "Permitir"
      permanence  = "P"
      component   = "Patron"
      owner       = "devops-fnc"
    }
    "sg_egress[\"C08\"]" = {
      id          = "C08"
      control     = "SG-OUT"
      parent_id   = aws_security_group.function.id
      source      = "SG-FUNCION"
      destination = "PL-S3"
      protocol    = "tcp"
      from_port   = 443
      to_port     = 443
      action      = "Permitir"
      permanence  = "P"
      component   = "Patron"
      owner       = "devops-fnc"
    }
    "sg_egress[\"C09\"]" = {
      id          = "C09"
      control     = "SG-OUT"
      parent_id   = aws_security_group.function.id
      source      = "SG-FUNCION"
      destination = "PL-DDB"
      protocol    = "tcp"
      from_port   = 443
      to_port     = 443
      action      = "Permitir"
      permanence  = "P"
      component   = "Patron"
      owner       = "devops-fnc"
    }
    "sg_egress[\"C10\"]" = {
      id          = "C10"
      control     = "SG-OUT"
      parent_id   = aws_security_group.function.id
      source      = "SG-FUNCION"
      destination = "SG-VPCE-REKOG"
      protocol    = "tcp"
      from_port   = 443
      to_port     = 443
      action      = "Permitir"
      permanence  = "P"
      component   = "Patron"
      owner       = "devops-fnc"
    }
    "sg_ingress[\"C11\"]" = {
      id          = "C11"
      control     = "SG-IN"
      parent_id   = aws_security_group.vpce_rekog.id
      source      = "SG-FUNCION"
      destination = "SG-VPCE-REKOG"
      protocol    = "tcp"
      from_port   = 443
      to_port     = 443
      action      = "Permitir"
      permanence  = "P"
      component   = "Patron"
      owner       = "devops-fnc"
    }
    "sg_egress[\"C12\"]" = {
      id          = "C12"
      control     = "SG-OUT"
      parent_id   = aws_security_group.clients_log.id
      source      = "SG-CLIENTES-LOG"
      destination = "SG-VPCE-LOGS"
      protocol    = "tcp"
      from_port   = 443
      to_port     = 443
      action      = "Permitir"
      permanence  = "P"
      component   = "Patron"
      owner       = "devops-fnc"
    }
    "sg_ingress[\"C13\"]" = {
      id          = "C13"
      control     = "SG-IN"
      parent_id   = aws_security_group.vpce_logs.id
      source      = "SG-CLIENTES-LOG"
      destination = "SG-VPCE-LOGS"
      protocol    = "tcp"
      from_port   = 443
      to_port     = 443
      action      = "Permitir"
      permanence  = "P"
      component   = "Patron"
      owner       = "devops-fnc"
    }
    "sg_egress[\"C14\"]" = {
      id          = "C14"
      control     = "SG-OUT"
      parent_id   = aws_security_group.clients_kms.id
      source      = "SG-CLIENTES-KMS"
      destination = "SG-VPCE-KMS"
      protocol    = "tcp"
      from_port   = 443
      to_port     = 443
      action      = "Permitir"
      permanence  = "P"
      component   = "Patron"
      owner       = "devops-fnc"
    }
    "sg_ingress[\"C15\"]" = {
      id          = "C15"
      control     = "SG-IN"
      parent_id   = aws_security_group.vpce_kms.id
      source      = "SG-CLIENTES-KMS"
      destination = "SG-VPCE-KMS"
      protocol    = "tcp"
      from_port   = 443
      to_port     = 443
      action      = "Permitir"
      permanence  = "P"
      component   = "Patron"
      owner       = "devops-fnc"
    }
    "sg_egress[\"C16\"]" = {
      id          = "C16"
      control     = "SG-OUT"
      parent_id   = aws_security_group.admin.id
      source      = "SG-ADMIN"
      destination = "SG-VPCE-SSM"
      protocol    = "tcp"
      from_port   = 443
      to_port     = 443
      action      = "Permitir"
      permanence  = "P"
      component   = "Admin"
      owner       = "devops-fnc"
    }
    "sg_ingress[\"C17\"]" = {
      id          = "C17"
      control     = "SG-IN"
      parent_id   = aws_security_group.vpce_ssm.id
      source      = var.admin_cidr
      destination = "SG-VPCE-SSM"
      protocol    = "tcp"
      from_port   = 443
      to_port     = 443
      action      = "Permitir"
      permanence  = "P"
      component   = "Admin"
      owner       = "devops-fnc"
    }
    "sg_ingress[\"C18\"]" = {
      id          = "C18"
      control     = "SG-IN"
      parent_id   = aws_security_group.resolver_in.id
      source      = var.dns_cidr
      destination = "SG-RESOLVER-IN"
      protocol    = "tcp/udp"
      from_port   = 53
      to_port     = 53
      action      = "Permitir"
      permanence  = "P"
      component   = "Privado"
      owner       = "devops-fnc"
    }
    "sg_egress[\"C19\"]" = {
      id          = "C19"
      control     = "SG-OUT"
      parent_id   = aws_security_group.resolver_out.id
      source      = "SG-RESOLVER-OUT"
      destination = var.dns_cidr
      protocol    = "tcp/udp"
      from_port   = 53
      to_port     = 53
      action      = "Permitir"
      permanence  = "P"
      component   = "Privado"
      owner       = "devops-fnc"
    }
    "sg_egress[\"C20\"]" = {
      id          = "C20"
      control     = "SG-OUT"
      parent_id   = aws_security_group.query.id
      source      = "SG-CONSULTA"
      destination = "PL-DDB"
      protocol    = "tcp"
      from_port   = 443
      to_port     = 443
      action      = "Permitir"
      permanence  = "P"
      component   = "Consulta"
      owner       = "devops-fnc"
    }
    "assertions[\"C21\"]" = {
      id          = "C21"
      control     = "INVARIANTE"
      parent_id   = "all-security-groups"
      source      = "Cualquier origen no enumerado"
      destination = "SG de workloads y endpoints"
      protocol    = "all"
      from_port   = 0
      to_port     = 0
      action      = "Denegar implícito"
      permanence  = "P"
      component   = "Patron"
      owner       = "devops-fnc"
    }
    "assertions[\"C22\"]" = {
      id          = "C22"
      control     = "INVARIANTE"
      parent_id   = "all-security-groups"
      source      = "SG de workloads y endpoints"
      destination = "Destinos no enumerados (cero 0.0.0.0/0)"
      protocol    = "all"
      from_port   = 0
      to_port     = 0
      action      = "Denegar implícito"
      permanence  = "P"
      component   = "Patron"
      owner       = "devops-fnc"
    }
    "nacl_ingress[\"N01\"]" = {
      id          = "N01"
      control     = "NACL-IN"
      parent_id   = aws_network_acl.private.id
      source      = var.visitor_cidr
      destination = "Subredes privadas del ambiente"
      protocol    = "all"
      from_port   = 0
      to_port     = 0
      action      = "Denegar"
      permanence  = "P"
      component   = "Patron"
      owner       = "devops-fnc"
    }
    "nacl_ingress[\"N02\"]" = {
      id          = "N02"
      control     = "NACL-IN"
      parent_id   = aws_network_acl.private.id
      source      = join(", ", var.authorized_private_cidrs)
      destination = "Subredes privadas del ambiente"
      protocol    = "tcp"
      from_port   = 443
      to_port     = 443
      action      = "Permitir"
      permanence  = "P"
      component   = "Patron"
      owner       = "devops-fnc"
    }
    "nacl_egress[\"N03\"]" = {
      id          = "N03"
      control     = "NACL-OUT"
      parent_id   = aws_network_acl.private.id
      source      = "Subredes privadas del ambiente"
      destination = join(", ", var.authorized_private_cidrs)
      protocol    = "tcp"
      from_port   = 443
      to_port     = 443
      action      = "Permitir"
      permanence  = "P"
      component   = "Patron"
      owner       = "devops-fnc"
    }
    "nacl_ingress[\"N04\"]" = {
      id          = "N04"
      control     = "NACL-IN"
      parent_id   = aws_network_acl.private.id
      source      = join(", ", var.authorized_private_cidrs)
      destination = "Subredes privadas del ambiente"
      protocol    = "tcp"
      from_port   = 53
      to_port     = 53
      action      = "Permitir"
      permanence  = "P"
      component   = "Patron"
      owner       = "devops-fnc"
    }
    "nacl_ingress[\"N05\"]" = {
      id          = "N05"
      control     = "NACL-IN"
      parent_id   = aws_network_acl.private.id
      source      = join(", ", var.authorized_private_cidrs)
      destination = "Subredes privadas del ambiente"
      protocol    = "udp"
      from_port   = 53
      to_port     = 53
      action      = "Permitir"
      permanence  = "P"
      component   = "Patron"
      owner       = "devops-fnc"
    }
    "nacl_egress[\"N06\"]" = {
      id          = "N06"
      control     = "NACL-OUT"
      parent_id   = aws_network_acl.private.id
      source      = "Subredes privadas del ambiente"
      destination = join(", ", var.authorized_private_cidrs)
      protocol    = "tcp"
      from_port   = 53
      to_port     = 53
      action      = "Permitir"
      permanence  = "P"
      component   = "Patron"
      owner       = "devops-fnc"
    }
    "nacl_egress[\"N07\"]" = {
      id          = "N07"
      control     = "NACL-OUT"
      parent_id   = aws_network_acl.private.id
      source      = "Subredes privadas del ambiente"
      destination = join(", ", var.authorized_private_cidrs)
      protocol    = "udp"
      from_port   = 53
      to_port     = 53
      action      = "Permitir"
      permanence  = "P"
      component   = "Patron"
      owner       = "devops-fnc"
    }
    "nacl_ingress[\"N08\"]" = {
      id          = "N08"
      control     = "NACL-IN"
      parent_id   = aws_network_acl.private.id
      source      = join(", ", var.authorized_private_cidrs)
      destination = "Subredes privadas del ambiente"
      protocol    = "tcp"
      from_port   = 1024
      to_port     = 65535
      action      = "Permitir"
      permanence  = "P"
      component   = "Patron"
      owner       = "devops-fnc"
    }
    "nacl_egress[\"N09\"]" = {
      id          = "N09"
      control     = "NACL-OUT"
      parent_id   = aws_network_acl.private.id
      source      = "Subredes privadas del ambiente"
      destination = join(", ", var.authorized_private_cidrs)
      protocol    = "tcp"
      from_port   = 1024
      to_port     = 65535
      action      = "Permitir"
      permanence  = "P"
      component   = "Patron"
      owner       = "devops-fnc"
    }
    "nacl_ingress[\"N10\"]" = {
      id          = "N10"
      control     = "NACL-IN"
      parent_id   = aws_network_acl.private.id
      source      = join(", ", var.authorized_private_cidrs)
      destination = "Subredes privadas del ambiente"
      protocol    = "udp"
      from_port   = 1024
      to_port     = 65535
      action      = "Permitir"
      permanence  = "P"
      component   = "Patron"
      owner       = "devops-fnc"
    }
    "nacl_egress[\"N11\"]" = {
      id          = "N11"
      control     = "NACL-OUT"
      parent_id   = aws_network_acl.private.id
      source      = "Subredes privadas del ambiente"
      destination = join(", ", var.authorized_private_cidrs)
      protocol    = "udp"
      from_port   = 1024
      to_port     = 65535
      action      = "Permitir"
      permanence  = "P"
      component   = "Patron"
      owner       = "devops-fnc"
    }
    "nacl_ingress[\"N12\"]" = {
      id          = "N12"
      control     = "NACL-IN"
      parent_id   = aws_network_acl.public.id
      source      = "0.0.0.0/0"
      destination = "Subredes de consulta pública"
      protocol    = "tcp"
      from_port   = 443
      to_port     = 443
      action      = "Permitir"
      permanence  = "P"
      component   = "Consulta"
      owner       = "devops-fnc"
    }
    "nacl_egress[\"N13\"]" = {
      id          = "N13"
      control     = "NACL-OUT"
      parent_id   = aws_network_acl.public.id
      source      = "Subredes de consulta pública"
      destination = "0.0.0.0/0"
      protocol    = "tcp"
      from_port   = 1024
      to_port     = 65535
      action      = "Permitir"
      permanence  = "P"
      component   = "Consulta"
      owner       = "devops-fnc"
    }
    "nacl_egress[\"N14\"]" = {
      id          = "N14"
      control     = "NACL-OUT"
      parent_id   = aws_network_acl.public.id
      source      = "Subredes de consulta pública"
      destination = var.app_cidr
      protocol    = "tcp"
      from_port   = 443
      to_port     = 443
      action      = "Permitir"
      permanence  = "P"
      component   = "Consulta"
      owner       = "devops-fnc"
    }
    "nacl_ingress[\"N15\"]" = {
      id          = "N15"
      control     = "NACL-IN"
      parent_id   = aws_network_acl.public.id
      source      = var.app_cidr
      destination = "Subredes de consulta pública"
      protocol    = "tcp"
      from_port   = 1024
      to_port     = 65535
      action      = "Permitir"
      permanence  = "P"
      component   = "Consulta"
      owner       = "devops-fnc"
    }
    "assertions[\"N16\"]" = {
      id          = "N16"
      control     = "INVARIANTE"
      parent_id   = "custom-network-acls"
      source      = "Cualquier dirección IP no contemplada"
      destination = "Subred protegida / destino no autorizado"
      protocol    = "all"
      from_port   = 0
      to_port     = 0
      action      = "Denegar implícito"
      permanence  = "P"
      component   = "Patron"
      owner       = "devops-fnc"
    }
  }
}


