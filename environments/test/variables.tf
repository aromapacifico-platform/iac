variable "environment" {
  description = "Short environment name used in resource names."
  type        = string

  validation {
    condition     = contains(["dev", "test", "prod"], var.environment)
    error_message = "environment must be dev, test or prod."
  }
}

variable "aws_region" {
  description = "Primary region of the platform."
  type        = string
  default     = "us-east-1"

  validation {
    condition     = var.aws_region == "us-east-1"
    error_message = "The primary region must be us-east-1 per governance decision #2."
  }
}

variable "availability_zones" {
  description = "The two availability zones the subnets are spread across."
  type        = list(string)

  validation {
    condition     = length(var.availability_zones) == 2
    error_message = "The addressing plan uses exactly two availability zones."
  }
}

variable "vpc_cidr" {
  description = "VPC block of this environment from the addressing plan (planning #7)."
  type        = string

  validation {
    condition     = can(cidrnetmask(var.vpc_cidr)) && endswith(var.vpc_cidr, "/16")
    error_message = "vpc_cidr must be a valid /16 block."
  }
}

variable "collection_center_cidrs" {
  description = "Collection center networks this environment may route to, keyed by AcopioID."
  type        = map(string)
  default     = {}

  validation {
    condition     = alltrue([for cidr in values(var.collection_center_cidrs) : can(cidrnetmask(cidr))])
    error_message = "Every collection center CIDR must be valid."
  }
}

variable "owner" {
  description = "Value of the Propietario tag."
  type        = string
  default     = "devops-fnc"

  validation {
    condition     = contains(["devops-fnc", "seguridad-cloud", "datos-agronomicos"], var.owner)
    error_message = "owner must be one of the Propietario values of the tag policy."
  }
}
