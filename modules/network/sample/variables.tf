variable "client" {
  description = "Client identifier."
  type        = string
  default     = "fnc"

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.client))
    error_message = "client must be lowercase alphanumeric with hyphens."
  }
}

variable "project" {
  description = "Project short identifier."
  type        = string
  default     = "aromapac"

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.project))
    error_message = "project must be lowercase alphanumeric with hyphens."
  }
}

variable "environment" {
  description = "Environment identifier."
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "test", "prod"], var.environment)
    error_message = "environment must be dev, test, or prod."
  }
}

variable "aws_region" {
  description = "AWS region for sample execution."
  type        = string
  default     = "us-east-1"

  validation {
    condition     = contains(["us-east-1", "us-east-2"], var.aws_region)
    error_message = "aws_region must be us-east-1 or us-east-2."
  }
}

variable "vpc_cidr" {
  description = "VPC CIDR block for the sample."
  type        = string
  default     = "10.50.0.0/16"

  validation {
    condition     = contains(["10.50.0.0/16", "10.60.0.0/16", "10.70.0.0/16"], var.vpc_cidr)
    error_message = "vpc_cidr must match an approved environment block."
  }
}

variable "availability_zones" {
  description = "Two distinct availability zones."
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]

  validation {
    condition     = length(var.availability_zones) == 2
    error_message = "Exactly two availability zones are required."
  }
}

variable "collection_center_department" {
  description = "Collection center department code (41 Cauca, 42 Huila, 43 Tolima)."
  type        = number
  default     = 41

  validation {
    condition     = contains([41, 42, 43], var.collection_center_department)
    error_message = "collection_center_department must be 41, 42, or 43."
  }
}
