variable "environment" {
  description = "Short environment name used in resource names."
  type        = string

  validation {
    condition     = var.environment == "test"
    error_message = "This root only manages test."
  }
}

variable "aws_region" {
  description = "Primary region of the platform."
  type        = string
  default     = "us-east-1"
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
    condition     = var.vpc_cidr == "10.60.0.0/16"
    error_message = "Use the approved address block for this environment."
  }
}

variable "collection_center_cidrs" {
  description = "Deprecated compatibility metadata only; does not create routes. Use collection_center_department and transit_gateway_id."
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

variable "endpoint_access" {
  description = "Real least-privilege endpoint grants, keyed exactly by s3 and dynamodb. No deployment fixture or wildcard principal/action/resource is allowed."
  type = map(object({
    principal_arns = set(string)
    actions        = set(string)
    resource_arns  = set(string)
  }))
  nullable = false
  validation {
    condition = toset(keys(var.endpoint_access)) == toset(["s3", "dynamodb"]) && alltrue([
      for service, access in var.endpoint_access :
      length(access.principal_arns) > 0 && length(access.actions) > 0 && length(access.resource_arns) > 0 &&
      alltrue([for arn in access.principal_arns : can(regex("^arn:aws:iam::[0-9]{12}:role/[^*?]+$", arn))]) &&
      alltrue([for action in access.actions : startswith(action, "${service}:") && !can(regex("[*?]", action))]) &&
      alltrue([for arn in access.resource_arns : service == "s3" ? (
        can(regex("^arn:aws:s3:::[a-z0-9][a-z0-9.-]{1,61}[a-z0-9](/.+)?$", arn)) &&
        !can(regex("[*?]", trimsuffix(arn, "/*")))
        ) : (
        can(regex("^arn:aws:dynamodb:${var.aws_region}:[0-9]{12}:table/[A-Za-z0-9_.-]{3,255}(/index/[A-Za-z0-9_.-]{3,255})?$", arn))
      )])
    ])
    error_message = "Supply both services with explicit IAM role ARNs, service actions and resource ARNs (only a trailing object /* is permitted)."
  }
}
variable "collection_center_department" {
  description = "Single pattern collection center; selection alone does not enable connectivity."
  type        = number
  default     = 41
  validation {
    condition     = contains([41, 42, 43], var.collection_center_department)
    error_message = "Select 41, 42 or 43."
  }
}
variable "transit_gateway_id" {
  description = "Central Network TGW shared through RAM; null keeps hybrid connectivity disabled."
  type        = string
  default     = null
  validation {
    condition = var.transit_gateway_id == null ? true : (
      var.environment == "prod" && var.aws_account_id != null && can(regex("^tgw-[0-9a-f]+$", var.transit_gateway_id))
    )
    error_message = "Hybrid access requires production, an explicit workload account ID and the central TGW ID."
  }
}
variable "aws_account_id" {
  description = "Expected workload account ID. Required when hybrid access is enabled; never inferred from a profile name."
  type        = string
  default     = null
  validation {
    condition     = var.aws_account_id == null ? true : can(regex("^[0-9]{12}$", var.aws_account_id))
    error_message = "Use an actual twelve-digit workload account ID."
  }
}
variable "s3_interface_security_group_id" {
  description = "Security-owned vpce_s3 SG in this VPC; null disables the optional hybrid S3 endpoint."
  type        = string
  default     = null
}
