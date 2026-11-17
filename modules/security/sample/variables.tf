variable "aws_region" {
  description = "AWS region for deploying sample resources."
  type        = string
  default     = "us-east-1"

  validation {
    condition     = var.aws_region == "us-east-1"
    error_message = "aws_region must be us-east-1 per governance decision #2."
  }
}

variable "environment" {
  description = "Sample execution environment."
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "test", "prod"], var.environment)
    error_message = "environment must be dev, test, or prod."
  }
}

variable "vpc_id" {
  description = "Sample VPC ID injected by root/fixture (PC-IAC-022)."
  type        = string

  validation {
    condition     = can(regex("^vpc-[a-z0-9]+$", var.vpc_id))
    error_message = "vpc_id must be a valid AWS VPC identifier."
  }
}

variable "private_subnet_ids" {
  description = "Sample private subnet IDs for NACL association."
  type        = list(string)

  validation {
    condition     = length(var.private_subnet_ids) > 0 && alltrue([for id in var.private_subnet_ids : can(regex("^subnet-[a-z0-9]+$", id))])
    error_message = "private_subnet_ids must contain valid subnet identifiers."
  }
}

variable "public_subnet_ids" {
  description = "Sample public subnet IDs for NACL association."
  type        = list(string)

  validation {
    condition     = length(var.public_subnet_ids) > 0 && alltrue([for id in var.public_subnet_ids : can(regex("^subnet-[a-z0-9]+$", id))])
    error_message = "public_subnet_ids must contain valid subnet identifiers."
  }
}

variable "authorized_private_cidrs" {
  description = "Authorized internal private CIDR blocks."
  type        = list(string)

  validation {
    condition     = length(var.authorized_private_cidrs) > 0 && alltrue([for c in var.authorized_private_cidrs : can(cidrnetmask(c))])
    error_message = "authorized_private_cidrs must contain valid CIDRs."
  }
}

variable "visitor_cidr" {
  description = "Visitor VLAN CIDR explicitly denied in private NACLs."
  type        = string

  validation {
    condition     = can(cidrnetmask(var.visitor_cidr))
    error_message = "visitor_cidr must be a valid CIDR."
  }
}

variable "log_authorized_cidr" {
  description = "Logistics reception CIDR for private API endpoint access."
  type        = string

  validation {
    condition     = can(cidrnetmask(var.log_authorized_cidr))
    error_message = "log_authorized_cidr must be a valid CIDR."
  }
}

variable "drone_backup_cidrs" {
  description = "Drone and backup sync CIDRs for S3 interface endpoint access."
  type        = list(string)

  validation {
    condition     = length(var.drone_backup_cidrs) > 0 && alltrue([for c in var.drone_backup_cidrs : can(cidrnetmask(c))])
    error_message = "drone_backup_cidrs must contain valid CIDRs."
  }
}

variable "admin_cidr" {
  description = "Administration network CIDR for SSM endpoint access."
  type        = string

  validation {
    condition     = can(cidrnetmask(var.admin_cidr))
    error_message = "admin_cidr must be a valid CIDR."
  }
}

variable "dns_cidr" {
  description = "Local DNS forwarders CIDR for Route 53 Inbound Resolver."
  type        = string

  validation {
    condition     = can(cidrnetmask(var.dns_cidr))
    error_message = "dns_cidr must be a valid CIDR."
  }
}

variable "app_cidr" {
  description = "Application subnet CIDR for public query NACL return rules."
  type        = string

  validation {
    condition     = can(cidrnetmask(var.app_cidr))
    error_message = "app_cidr must be a valid CIDR."
  }
}

variable "kms_deletion_window_in_days" {
  description = "KMS key deletion window in days."
  type        = number
  default     = 30

  validation {
    condition     = var.kms_deletion_window_in_days >= 7 && var.kms_deletion_window_in_days <= 30
    error_message = "kms_deletion_window_in_days must be between 7 and 30."
  }
}

variable "additional_tags" {
  description = "Additional tags to pass to the sample module."
  type        = map(string)
  default     = {}

  validation {
    condition     = can(keys(var.additional_tags))
    error_message = "additional_tags must be a valid key-value map."
  }
}
