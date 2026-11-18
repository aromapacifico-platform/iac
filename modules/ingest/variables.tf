variable "aws_account_id" {
  description = "Workload account ID from root discovery."
  type        = string
  validation {
    condition     = can(regex("^[0-9]{12}$", var.aws_account_id))
    error_message = "Use a twelve-digit account ID."
  }
}

variable "aws_region" {
  description = "Primary AWS region."
  type        = string
  validation {
    condition     = var.aws_region == "us-east-1"
    error_message = "Use us-east-1."
  }
}

variable "kms_key_arn" {
  description = "Security data CMK ARN for both tables and reception queues."
  type        = string
  validation {
    condition     = can(regex("^arn:aws:kms:us-east-1:[0-9]{12}:key/[a-f0-9-]+$", var.kms_key_arn)) && startswith(var.kms_key_arn, "arn:aws:kms:${var.aws_region}:${var.aws_account_id}:key/")
    error_message = "Use the security data key ARN."
  }
}

variable "ingest_role_arn" {
  description = "Existing security-owned IoT rule action role."
  type        = string
  validation {
    condition     = can(regex("^arn:aws:iam::[0-9]{12}:role/[^*?]+$", var.ingest_role_arn)) && startswith(var.ingest_role_arn, "arn:aws:iam::${var.aws_account_id}:role/")
    error_message = "Use a specific IAM role ARN."
  }
}

variable "farm_id" {
  description = "Authorized farm identifier used in physical MQTT topics."
  type        = string
  validation {
    condition     = can(regex("^[A-Z]{3}-F[0-9]{3,6}$", var.farm_id))
    error_message = "Use a farm ID such as CAU-F001."
  }
}

variable "thing_name" {
  description = "Root-built IoT thing name and required MQTT ClientId."
  type        = string
  validation {
    condition     = can(regex("^[a-zA-Z0-9_-]{1,128}$", var.thing_name))
    error_message = "Use a valid exact IoT thing name."
  }
}

variable "resource_names" {
  description = "Root-built final names, matching the security role resource contract."
  type        = object({ telemetry = string, thresholds = string, queue = string, dlq = string, rule = string, policy = string })
  validation {
    condition     = alltrue([for n in [var.resource_names.telemetry, var.resource_names.thresholds, var.resource_names.queue, var.resource_names.dlq, var.resource_names.policy] : can(regex("^[A-Za-z0-9_-]{3,80}$", n))]) && can(regex("^[A-Za-z][A-Za-z0-9_]{0,127}$", var.resource_names.rule))
    error_message = "Use AWS-valid names; rule names contain only letters, digits and underscores."
  }
}

variable "additional_tags" {
  description = "Additional tags; identity and Name tags are owned by the module."
  type        = map(string)
  default     = {}
  validation {
    condition     = alltrue([for k, v in var.additional_tags : length(k) > 0 && length(v) > 0])
    error_message = "Tag keys and values must not be empty."
  }
}
