variable "client" {
  description = "Client identifier (e.g. fnc)."
  type        = string
  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.client))
    error_message = "client must be lowercase alphanumeric with hyphens."
  }
}

variable "project" {
  description = "Project name (e.g. aromapacifico)."
  type        = string
  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.project))
    error_message = "project must be lowercase alphanumeric with hyphens."
  }
}

variable "environment" {
  description = "Deployment environment."
  type        = string
  validation {
    condition     = contains(["dev", "test", "prod"], var.environment)
    error_message = "environment must be dev, test, or prod."
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

variable "aws_region" {
  description = "Primary project region."
  type        = string
  default     = "us-east-1"
  validation {
    condition     = var.aws_region == "us-east-1"
    error_message = "Use us-east-1."
  }
}
