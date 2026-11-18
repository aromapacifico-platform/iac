variable "environment" {
  description = "Environment whose account receives the state bucket."
  type        = string

  validation {
    condition     = contains(["dev", "test", "prod"], var.environment)
    error_message = "environment must be dev, test or prod."
  }
}

variable "aws_region" {
  description = "Region of the state bucket and key."
  type        = string
  default     = "us-east-1"

  validation {
    condition     = contains(["us-east-1", "us-east-2"], var.aws_region)
    error_message = "aws_region must be us-east-1 or us-east-2 per AromaPacifico governance."
  }
}

variable "state_bucket_name" {
  description = "Name of the state bucket. Defaults to aromapacifico-tfstate-<environment>."
  type        = string
  default     = null

  validation {
    condition     = var.state_bucket_name == null ? true : can(regex("^[a-z0-9][a-z0-9.-]{1,61}[a-z0-9]$", var.state_bucket_name))
    error_message = "state_bucket_name must be null or a valid S3 bucket name."
  }
}

variable "noncurrent_version_retention_days" {
  description = "Days to keep previous versions of each state file."
  type        = number
  default     = 90

  validation {
    condition     = var.noncurrent_version_retention_days >= 30 && var.noncurrent_version_retention_days <= 3650
    error_message = "noncurrent_version_retention_days must be between 30 and 3650 days."
  }
}
