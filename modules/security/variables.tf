variable "client" {
  description = "Client identifier (e.g. fnc)."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.client))
    error_message = "client must be lowercase alphanumeric with hyphens."
  }
}

variable "project" {
  description = "Project name identifier (e.g. aromapacifico)."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.project))
    error_message = "project must be lowercase alphanumeric with hyphens."
  }
}

variable "environment" {
  description = "Deployment environment name."
  type        = string

  validation {
    condition     = contains(["dev", "test", "prod"], var.environment)
    error_message = "environment must be dev, test, or prod."
  }
}

variable "vpc_id" {
  description = "Target Virtual Private Cloud (VPC) ID for security resources."
  type        = string

  validation {
    condition     = can(regex("^vpc-[a-z0-9]+$", var.vpc_id))
    error_message = "vpc_id must be a valid AWS VPC identifier starting with vpc-."
  }
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs where private Network ACLs apply."
  type        = list(string)
  default     = []

  validation {
    condition     = alltrue([for id in var.private_subnet_ids : can(regex("^subnet-[a-z0-9]+$", id))])
    error_message = "All elements in private_subnet_ids must be valid subnet identifiers (subnet-xxx)."
  }
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs where public Network ACLs apply."
  type        = list(string)
  default     = []

  validation {
    condition     = alltrue([for id in var.public_subnet_ids : can(regex("^subnet-[a-z0-9]+$", id))])
    error_message = "All elements in public_subnet_ids must be valid subnet identifiers (subnet-xxx)."
  }
}

variable "authorized_private_cidrs" {
  description = "List of authorized private CIDR blocks allowed in NACLs and security groups."
  type        = list(string)
  default     = ["10.0.0.0/8"]

  validation {
    condition     = alltrue([for cidr in var.authorized_private_cidrs : can(cidrnetmask(cidr))])
    error_message = "All elements in authorized_private_cidrs must be valid CIDR blocks."
  }
}

variable "visitor_cidr" {
  description = "Visitor VLAN CIDR block explicitly denied in NACL N01."
  type        = string
  default     = "10.41.5.0/24"

  validation {
    condition     = can(cidrnetmask(var.visitor_cidr))
    error_message = "visitor_cidr must be a valid CIDR block."
  }
}

variable "log_authorized_cidr" {
  description = "CIDR block for authorized logistics/acopio reception clients (rule C04)."
  type        = string
  default     = "10.41.3.0/24"

  validation {
    condition     = can(cidrnetmask(var.log_authorized_cidr))
    error_message = "log_authorized_cidr must be a valid CIDR block."
  }
}

variable "drone_backup_cidrs" {
  description = "List of CIDR blocks for drone bases and backup hosts (rule C05)."
  type        = list(string)
  default     = ["10.41.20.0/24"]

  validation {
    condition     = alltrue([for cidr in var.drone_backup_cidrs : can(cidrnetmask(cidr))])
    error_message = "All elements in drone_backup_cidrs must be valid CIDR blocks."
  }
}

variable "admin_cidr" {
  description = "CIDR block for administration workstations (rules C16 and C17)."
  type        = string
  default     = "10.41.1.0/24"

  validation {
    condition     = can(cidrnetmask(var.admin_cidr))
    error_message = "admin_cidr must be a valid CIDR block."
  }
}

variable "dns_cidr" {
  description = "CIDR block for local DNS forwarders and servers (rules C18 and C19)."
  type        = string
  default     = "10.41.10.0/24"

  validation {
    condition     = can(cidrnetmask(var.dns_cidr))
    error_message = "dns_cidr must be a valid CIDR block."
  }
}

variable "app_cidr" {
  description = "CIDR block for internal application services (rules N14 and N15)."
  type        = string
  default     = "10.50.10.0/24"

  validation {
    condition     = can(cidrnetmask(var.app_cidr))
    error_message = "app_cidr must be a valid CIDR block."
  }
}

variable "kms_deletion_window_in_days" {
  description = "Duration in days for KMS key deletion waiting period."
  type        = number
  default     = 30

  validation {
    condition     = var.kms_deletion_window_in_days >= 7 && var.kms_deletion_window_in_days <= 30
    error_message = "kms_deletion_window_in_days must be between 7 and 30 days."
  }
}

variable "additional_tags" {
  description = "Additional resource-specific tags."
  type        = map(string)
  default     = {}

  validation {
    condition     = can(keys(var.additional_tags))
    error_message = "additional_tags must be a valid key-value map."
  }
}
