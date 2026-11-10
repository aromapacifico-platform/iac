locals {
  center_id = "ACOPIO-${lookup({ "41" = "CAUCA", "42" = "HUILA", "43" = "TOLIMA" }, tostring(var.collection_center_department), "INVALID")}"
  operational_cidrs = {
    logistics = "10.${var.collection_center_department}.3.0/24"
    servers   = "10.${var.collection_center_department}.10.0/24"
  }
}

resource "aws_customer_gateway" "this" {
  count      = var.connection == null ? 0 : 1
  bgp_asn    = 65000 + var.collection_center_department
  ip_address = var.connection.customer_gateway_public_ip
  type       = "ipsec.1"
  tags       = { Name = "${var.name_prefix}-cgw", AcopioID = local.center_id }
}

resource "aws_vpn_connection" "this" {
  count                   = var.connection == null ? 0 : 1
  customer_gateway_id     = aws_customer_gateway.this[0].id
  transit_gateway_id      = var.transit_gateway_id
  type                    = "ipsec.1"
  static_routes_only      = false
  preshared_key_storage   = "SecretsManager"
  local_ipv4_network_cidr = "10.${var.collection_center_department}.0.0/16"
  # Selectors include hub DNS; the isolated TGW table controls actual reachability.
  remote_ipv4_network_cidr             = "10.0.0.0/8"
  tunnel1_ike_versions                 = ["ikev2"]
  tunnel2_ike_versions                 = ["ikev2"]
  tunnel1_phase1_encryption_algorithms = ["AES256"]
  tunnel2_phase1_encryption_algorithms = ["AES256"]
  tunnel1_phase2_encryption_algorithms = ["AES256"]
  tunnel2_phase2_encryption_algorithms = ["AES256"]
  tunnel1_phase1_integrity_algorithms  = ["SHA2-256"]
  tunnel2_phase1_integrity_algorithms  = ["SHA2-256"]
  tunnel1_phase2_integrity_algorithms  = ["SHA2-256"]
  tunnel2_phase2_integrity_algorithms  = ["SHA2-256"]
  tunnel1_phase1_dh_group_numbers      = [14]
  tunnel2_phase1_dh_group_numbers      = [14]
  tunnel1_phase2_dh_group_numbers      = [14]
  tunnel2_phase2_dh_group_numbers      = [14]
  tunnel1_dpd_timeout_action           = "restart"
  tunnel2_dpd_timeout_action           = "restart"
  tunnel1_log_options {
    cloudwatch_log_options {
      log_enabled       = true
      log_group_arn     = var.connection.tunnel_log_group_arn
      log_output_format = "json"
    }
  }
  tunnel2_log_options {
    cloudwatch_log_options {
      log_enabled       = true
      log_group_arn     = var.connection.tunnel_log_group_arn
      log_output_format = "json"
    }
  }
  tags = { Name = "${var.name_prefix}-vpn", AcopioID = local.center_id }
}

resource "aws_ec2_transit_gateway_vpc_attachment_accepter" "production" {
  count                                           = var.connection == null ? 0 : 1
  transit_gateway_attachment_id                   = var.connection.production_attachment_id
  transit_gateway_default_route_table_association = false
  transit_gateway_default_route_table_propagation = false
  tags                                            = { Name = "${var.name_prefix}-prod", AcopioID = local.center_id }
}

resource "aws_ec2_transit_gateway_route_table" "this" {
  count              = var.connection == null ? 0 : 1
  transit_gateway_id = var.transit_gateway_id
  tags               = { Name = "${var.name_prefix}-isolated", AcopioID = local.center_id }
}

resource "aws_ec2_transit_gateway_route_table_association" "production" {
  count                          = var.connection == null ? 0 : 1
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment_accepter.production[0].id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.this[0].id
}
resource "aws_ec2_transit_gateway_route_table_association" "vpn" {
  count                          = var.connection == null ? 0 : 1
  transit_gateway_attachment_id  = aws_vpn_connection.this[0].transit_gateway_attachment_id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.this[0].id
}

# No VPN propagation: TGW cannot filter learned BGP routes. Only these /24s
# are installed, so advertising visitors cannot create a forwarding path.
resource "aws_ec2_transit_gateway_route" "collection_center" {
  for_each                       = var.connection == null ? {} : local.operational_cidrs
  destination_cidr_block         = each.value
  transit_gateway_attachment_id  = aws_vpn_connection.this[0].transit_gateway_attachment_id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.this[0].id
}
resource "aws_ec2_transit_gateway_route" "production" {
  count                          = var.connection == null ? 0 : 1
  destination_cidr_block         = "10.70.0.0/16"
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment_accepter.production[0].id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.this[0].id
}
resource "aws_ec2_transit_gateway_route" "hub_dns" {
  for_each                       = var.hub_dns == null || var.connection == null ? toset([]) : var.hub_dns.resolver_ips
  destination_cidr_block         = "${each.value}/32"
  transit_gateway_attachment_id  = var.hub_dns.attachment_id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.this[0].id
}
resource "aws_ec2_transit_gateway_route" "hub_return" {
  for_each                       = var.hub_dns == null || var.connection == null ? {} : local.operational_cidrs
  destination_cidr_block         = each.value
  transit_gateway_attachment_id  = aws_vpn_connection.this[0].transit_gateway_attachment_id
  transit_gateway_route_table_id = var.hub_dns.route_table_id
}
