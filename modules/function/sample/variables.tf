# ==============================================================================
# Sample Fixture Variables (PC-IAC-002)
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
  description = "Target deployment environment."
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
    condition     = var.aws_region == "us-east-1"
    error_message = "AWS region must strictly be us-east-1 per AromaPacifico base decisions."
  }
}

variable "expedientes_table_name" {
  type        = string
  description = "Name of target DynamoDB table for agricultural focus expedientes."
  default     = "fnc-aromapacifico-dev-dynamo-expedientes"

  validation {
    condition     = length(var.expedientes_table_name) > 3 && length(var.expedientes_table_name) <= 64
    error_message = "Expedientes table name must be between 3 and 64 characters."
  }
}

variable "mock_kms_key_objects_arn" {
  type        = string
  description = "Mock KMS key ARN for S3 objects encryption."
  default     = "arn:aws:kms:us-east-1:111122223333:key/12345678-1234-1234-1234-123456789012"

  validation {
    condition     = can(regex("^arn:aws:kms:[a-z0-9-]+:[0-9]{12}:key/[a-zA-Z0-9-]+$", var.mock_kms_key_objects_arn))
    error_message = "Must be a valid AWS KMS key ARN."
  }
}

variable "mock_kms_key_data_arn" {
  type        = string
  description = "Mock KMS key ARN for DynamoDB data and SQS DLQ encryption."
  default     = "arn:aws:kms:us-east-1:111122223333:key/87654321-4321-4321-4321-210987654321"

  validation {
    condition     = can(regex("^arn:aws:kms:[a-z0-9-]+:[0-9]{12}:key/[a-zA-Z0-9-]+$", var.mock_kms_key_data_arn))
    error_message = "Must be a valid AWS KMS key ARN."
  }
}

variable "additional_tags" {
  type        = map(string)
  description = "Additional tags to merge."
  default     = {}

  validation {
    condition     = can(keys(var.additional_tags))
    error_message = "additional_tags must be a valid map."
  }
}
