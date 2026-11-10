variable "network_account_id" {
  description = "Actual AromaPacifico-Network account ID, independently verified by STS."
  type        = string
  validation {
    condition     = can(regex("^[0-9]{12}$", var.network_account_id))
    error_message = "Supply the real Network account ID."
  }
}
variable "network_role_arn" {
  description = "Existing Network deployment role. Security owns its trust and permissions."
  type        = string
  validation {
    condition     = can(regex("^arn:aws:iam::${var.network_account_id}:role/.+$", var.network_role_arn))
    error_message = "The role must belong to the declared Network account."
  }
}
variable "production_account_id" {
  description = "Actual production account receiving the central TGW RAM share."
  type        = string
  validation {
    condition     = can(regex("^[0-9]{12}$", var.production_account_id)) && var.production_account_id != var.network_account_id
    error_message = "Supply a distinct real production account ID."
  }
}
variable "collection_center_department" {
  description = "Department selected for the single production VPN pattern."
  type        = number
  default     = 41
  nullable    = false
  validation {
    condition     = contains([41, 42, 43], var.collection_center_department)
    error_message = "Select department 41, 42 or 43."
  }
}
variable "connection" {
  description = "Null disables the VPN. Public CPE IPv4 and production attachment must be supplied together. Logs belong to security."
  type = object({
    customer_gateway_public_ip      = string
    production_attachment_id        = string
    production_collection_center_id = string
    tunnel_log_group_arn            = string
  })
  default = null
  validation {
    condition = var.connection == null ? true : (
      var.connection.production_collection_center_id == local.collection_center_id &&
      can(cidrnetmask("${var.connection.customer_gateway_public_ip}/32")) &&
      !can(regex("^(0\\.|10\\.|127\\.|169\\.254\\.|172\\.(1[6-9]|2[0-9]|3[01])\\.|192\\.168\\.|100\\.(6[4-9]|[7-9][0-9]|1[01][0-9]|12[0-7])\\.|22[4-9]\\.|2[3-5][0-9]\\.)", var.connection.customer_gateway_public_ip)) &&
      can(regex("^tgw-attach-[0-9a-f]+$", var.connection.production_attachment_id)) &&
      can(regex("^arn:aws:logs:us-east-1:${var.network_account_id}:log-group:.+", var.connection.tunnel_log_group_arn))
    )
    error_message = "An enabled VPN needs matching production collection center metadata, public CPE IPv4, production TGW attachment ID and security-owned tunnel log group ARN."
  }
}
variable "hub_dns" {
  description = "Optional existing Network hub DNS contract: isolated hub route table, attachment and two inbound resolver /32 addresses."
  type = object({
    attachment_id  = string
    route_table_id = string
    resolver_ips   = set(string)
  })
  default = null
  validation {
    condition = var.hub_dns == null ? true : (
      var.connection != null &&
      can(regex("^tgw-attach-[0-9a-f]+$", var.hub_dns.attachment_id)) &&
      can(regex("^tgw-rtb-[0-9a-f]+$", var.hub_dns.route_table_id)) &&
      length(var.hub_dns.resolver_ips) == 2 &&
      alltrue([for ip in var.hub_dns.resolver_ips : can(cidrnetmask("${ip}/32")) && startswith(ip, "10.80.")])
    )
    error_message = "Hub DNS requires an active connection, hub attachment/table IDs and two distinct resolver IPv4 addresses in 10.80.0.0/16."
  }
}

variable "create_transit_gateway" {
  description = "Explicit opt-in to create the single central TGW. Otherwise supply an existing centrally managed TGW ID."
  type        = bool
  default     = false
  validation {
    condition     = var.create_transit_gateway != (var.existing_transit_gateway_id != null)
    error_message = "Choose exactly one central ownership mode: create_transit_gateway=true or an existing_transit_gateway_id. Audit the Network account before choosing creation."
  }
}
variable "existing_transit_gateway_id" {
  description = "Existing TGW owned by the central Network team; its lifecycle remains in its original state."
  type        = string
  default     = null
  validation {
    condition     = var.existing_transit_gateway_id == null ? true : can(regex("^tgw-[0-9a-f]+$", var.existing_transit_gateway_id))
    error_message = "Supply a valid existing central TGW ID."
  }
}
