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
}

variable "state_bucket_name" {
  description = "Name of the state bucket. Defaults to aromapacifico-tfstate-<environment>."
  type        = string
  default     = null
}

variable "noncurrent_version_retention_days" {
  description = "Days to keep previous versions of each state file."
  type        = number
  default     = 90
}
