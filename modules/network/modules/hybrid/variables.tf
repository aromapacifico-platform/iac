variable "name_prefix" {
  description = "Central connection name prefix."
  type        = string
}
variable "transit_gateway_id" {
  description = "Central TGW ID; required only for an enabled connection."
  type        = string
  default     = null
  validation {
    condition     = var.connection == null || can(regex("^tgw-[0-9a-f]+$", var.transit_gateway_id))
    error_message = "Supply the central TGW ID."
  }
}
variable "collection_center_department" {
  description = "Single selected department: Cauca 41, Huila 42 or Tolima 43."
  type        = number
  default     = 41
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
      var.connection.production_collection_center_id == local.center_id &&
      can(cidrnetmask("${var.connection.customer_gateway_public_ip}/32")) &&
      !can(regex("^(0\\.|10\\.|127\\.|169\\.254\\.|172\\.(1[6-9]|2[0-9]|3[01])\\.|192\\.168\\.|100\\.(6[4-9]|[7-9][0-9]|1[01][0-9]|12[0-7])\\.|22[4-9]\\.|2[3-5][0-9]\\.)", var.connection.customer_gateway_public_ip)) &&
      can(regex("^tgw-attach-[0-9a-f]+$", var.connection.production_attachment_id)) &&
      can(regex("^arn:aws:logs:us-east-1:[0-9]{12}:log-group:.+", var.connection.tunnel_log_group_arn))
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
