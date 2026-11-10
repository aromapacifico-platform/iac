# ==============================================================================
# Governance & Identification Variables (PC-IAC-002, PC-IAC-003)
# ==============================================================================

variable "client" {
  type        = string
  description = "Client identifier (e.g. fnc)."
  default     = "fnc"

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.client)) && length(var.client) <= 8
    error_message = "Client identifier must be lowercase alphanumeric and at most 8 characters."
  }
}

variable "project" {
  type        = string
  description = "Project name identifier (e.g. aromapacifico)."
  default     = "aromapacifico"

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.project)) && length(var.project) <= 16
    error_message = "Project name must be lowercase alphanumeric and at most 16 characters."
  }
}

variable "environment" {
  type        = string
  description = "Target deployment environment (desarrollo, pruebas, produccion, dev, test, prod)."
  default     = "desarrollo"

  validation {
    condition     = contains(["desarrollo", "pruebas", "produccion", "dev", "test", "prod"], var.environment)
    error_message = "Environment must be one of: desarrollo, pruebas, produccion, dev, test, prod."
  }
}

variable "aws_region" {
  type        = string
  description = "AWS deployment region."
  default     = "us-east-1"

  validation {
    condition     = contains(["us-east-1", "us-east-2"], var.aws_region)
    error_message = "AWS region must be us-east-1 (primary) or us-east-2 (backup)."
  }
}

variable "name_prefix" {
  type        = string
  description = "Optional custom physical name prefix. If omitted, constructed from governance variables."
  default     = ""

  validation {
    condition     = length(var.name_prefix) <= 24
    error_message = "Name prefix must be at most 24 characters to respect PC-IAC-003 constraints."
  }
}

# ==============================================================================
# Workload & Service Variables (Issue #25, PC-IAC-020)
# ==============================================================================

variable "expedientes_table_name" {
  type        = string
  description = "Name of the target DynamoDB table for agricultural focus expedientes."
  default     = "fnc-aromapacifico-dev-dynamo-expedientes"

  validation {
    condition     = length(var.expedientes_table_name) > 3 && length(var.expedientes_table_name) <= 64
    error_message = "Expedientes table name must be between 3 and 64 characters."
  }
}

variable "kms_key_objects_arn" {
  type        = string
  description = "Customer Managed KMS Key ARN for S3 confirmation objects encryption."

  validation {
    condition     = can(regex("^arn:aws:kms:[a-z0-9-]+:[0-9]{12}:key/[a-zA-Z0-9-]+$", var.kms_key_objects_arn))
    error_message = "KMS key objects ARN must be a valid AWS KMS key ARN."
  }
}

variable "kms_key_data_arn" {
  type        = string
  description = "Customer Managed KMS Key ARN for DynamoDB records and SQS DLQ encryption."

  validation {
    condition     = can(regex("^arn:aws:kms:[a-z0-9-]+:[0-9]{12}:key/[a-zA-Z0-9-]+$", var.kms_key_data_arn))
    error_message = "KMS key data ARN must be a valid AWS KMS key ARN."
  }
}

variable "kms_key_logs_arn" {
  type        = string
  description = "Optional Customer Managed KMS Key ARN for CloudWatch Log Group encryption."
  default     = ""

  validation {
    condition     = var.kms_key_logs_arn == "" || can(regex("^arn:aws:kms:[a-z0-9-]+:[0-9]{12}:key/[a-zA-Z0-9-]+$", var.kms_key_logs_arn))
    error_message = "KMS key logs ARN must be empty or a valid AWS KMS key ARN."
  }
}

variable "notification_filter_prefix" {
  type        = string
  description = "S3 object key prefix filter that triggers the focus confirmation function."
  default     = "raw-images/focos/"

  validation {
    condition     = length(var.notification_filter_prefix) <= 128
    error_message = "Notification filter prefix must be at most 128 characters."
  }
}

variable "notification_filter_suffix" {
  type        = string
  description = "S3 object key suffix filter that triggers the focus confirmation function."
  default     = ".jpg"

  validation {
    condition     = length(var.notification_filter_suffix) <= 16
    error_message = "Notification filter suffix must be at most 16 characters."
  }
}

variable "rekognition_min_confidence" {
  type        = number
  description = "Minimum confidence score (0-100) for Rekognition PII label and face detection."
  default     = 50.0

  validation {
    condition     = var.rekognition_min_confidence >= 10.0 && var.rekognition_min_confidence <= 99.0
    error_message = "Rekognition minimum confidence must be between 10.0 and 99.0."
  }
}

variable "lambda_memory_size" {
  type        = number
  description = "Memory allocated to the focus confirmation Lambda function in megabytes."
  default     = 512

  validation {
    condition     = var.lambda_memory_size >= 128 && var.lambda_memory_size <= 3008
    error_message = "Lambda memory size must be between 128 and 3008 MB."
  }
}

variable "lambda_timeout" {
  type        = number
  description = "Execution timeout for the Lambda function in seconds."
  default     = 60

  validation {
    condition     = var.lambda_timeout >= 5 && var.lambda_timeout <= 300
    error_message = "Lambda execution timeout must be between 5 and 300 seconds."
  }
}

variable "log_retention_in_days" {
  type        = number
  description = "CloudWatch log retention window in days."
  default     = 30

  validation {
    condition     = contains([1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 730, 1827], var.log_retention_in_days)
    error_message = "Log retention must be a valid CloudWatch retention window."
  }
}

variable "create_iam_role" {
  type        = bool
  description = "Whether to create a dedicated IAM role for the Lambda function within this module."
  default     = true

  validation {
    condition     = contains([true, false], var.create_iam_role)
    error_message = "create_iam_role must be a boolean."
  }
}

variable "custom_iam_role_arn" {
  type        = string
  description = "External IAM role ARN to attach to Lambda when create_iam_role is false."
  default     = ""

  validation {
    condition     = var.custom_iam_role_arn == "" || can(regex("^arn:aws:iam::[0-9]{12}:role/[a-zA-Z0-9+=,.@_-]+$", var.custom_iam_role_arn))
    error_message = "Custom IAM role ARN must be empty or a valid AWS IAM role ARN."
  }
}

variable "subnet_ids" {
  type        = list(string)
  description = "Optional list of private subnet IDs for Lambda VPC integration per PC-IAC-020."
  default     = []

  validation {
    condition     = length(var.subnet_ids) == 0 || can([for s in var.subnet_ids : regex("^subnet-[a-z0-9]+$", s)])
    error_message = "Subnet IDs must follow AWS subnet format (subnet-xxxxxxxx)."
  }
}

variable "security_group_ids" {
  type        = list(string)
  description = "Optional list of Security Group IDs for Lambda VPC interface per PC-IAC-020."
  default     = []

  validation {
    condition     = length(var.security_group_ids) == 0 || can([for s in var.security_group_ids : regex("^sg-[a-z0-9]+$", s)])
    error_message = "Security group IDs must follow AWS security group format (sg-xxxxxxxx)."
  }
}

variable "additional_tags" {
  type        = map(string)
  description = "Additional tags to merge with default tags (PC-IAC-004)."
  default     = {}

  validation {
    condition     = can(keys(var.additional_tags))
    error_message = "additional_tags must be a valid map of key-value pairs."
  }
}

