variable "name_prefix" {
  description = "Resource name prefix supplied by the environment."
  type        = string
  nullable    = false

  validation {
    condition     = length(trimspace(var.name_prefix)) > 0
    error_message = "The resource name prefix must not be empty."
  }
}

variable "vpc_cidr" {
  description = "IPv4 /16 CIDR assigned to the environment in the approved address plan."
  type        = string
  nullable    = false

  validation {
    condition = (
      contains(["10.50.0.0/16", "10.60.0.0/16", "10.70.0.0/16"], var.vpc_cidr)
    )
    error_message = "Use the approved dev, test or prod /16; collection center ranges are reserved."
  }
}

variable "availability_zones" {
  description = "Two distinct availability zones in the deployment region."
  type        = list(string)
  nullable    = false

  validation {
    condition = (
      length(var.availability_zones) == 2 &&
      length(distinct(var.availability_zones)) == 2 &&
      alltrue([for zone in var.availability_zones : can(regex("^${var.aws_region}[a-z]$", zone))])
    )
    error_message = "Exactly two distinct availability zones in aws_region are required."
  }
}

variable "aws_region" {
  description = "AWS region matching the provider configuration."
  type        = string
  nullable    = false

  validation {
    condition = can(regex(
      "^[a-z]{2}(-[a-z]+)+-[0-9]+$",
      var.aws_region
    ))
    error_message = "A valid AWS region name is required."
  }
}

variable "gateway_endpoint_policies" {
  description = "JSON endpoint policies for S3 and DynamoDB, supplied by the environment."
  type        = map(string)
  nullable    = false

  validation {
    condition = (
      toset(keys(var.gateway_endpoint_policies)) ==
      toset(["s3", "dynamodb"])
    )
    error_message = "Provide exactly the s3 and dynamodb endpoint policies."
  }

  validation {
    condition = alltrue([
      for policy in values(var.gateway_endpoint_policies) :
      can(jsondecode(policy))
    ])
    error_message = "Each endpoint policy must contain valid JSON."
  }
}

variable "collection_center_department" {
  description = "Collection center department: 41 for Cauca, 42 for Huila, or 43 for Tolima."
  type        = number
  default     = 41
  nullable    = false

  validation {
    condition = contains(
      [41, 42, 43],
      var.collection_center_department
    )
    error_message = "The collection center department must be 41, 42, or 43."
  }
}

variable "transit_gateway_id" {
  description = "Shared central TGW ID. Null disables all hybrid attachments and routes. Only production may connect."
  type        = string
  default     = null

  validation {
    condition = var.transit_gateway_id == null ? true : (
      can(regex("^tgw-[0-9a-f]+$", var.transit_gateway_id)) && var.vpc_cidr == "10.70.0.0/16"
    )
    error_message = "Only the approved production VPC may attach to a real collection center through a valid TGW ID."
  }
}

variable "s3_interface" {
  description = "Optional hybrid S3 endpoint. Security supplies its SG; clients use the exported endpoint-specific DNS names."
  type = object({
    security_group_id = string
    policy            = string
  })
  default = null

  validation {
    condition = var.s3_interface == null ? true : (
      can(regex("^sg-[0-9a-f]+$", var.s3_interface.security_group_id)) && can(jsondecode(var.s3_interface.policy))
    )
    error_message = "S3 interface access requires a security-owned SG ID and a valid JSON endpoint policy."
  }
}
