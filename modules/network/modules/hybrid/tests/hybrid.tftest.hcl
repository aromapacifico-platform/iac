# All addresses, accounts and IDs in this file are test fixtures only.
mock_provider "aws" {
  override_during = plan
  mock_resource "aws_vpn_connection" {
    defaults = {
      id                             = "vpn-0123456789abcdef0"
      transit_gateway_attachment_id  = "tgw-attach-00000000000000002"
      tunnel1_address                = "192.0.2.10"
      tunnel2_address                = "192.0.2.11"
      tunnel1_preshared_key          = "REDACTED"
      tunnel2_preshared_key          = "REDACTED"
      customer_gateway_configuration = "<redacted/>"
    }
  }
  mock_resource "aws_ec2_transit_gateway_vpc_attachment_accepter" {
    defaults = { id = "tgw-attach-00000000000000001" }
  }
}
variables {
  name_prefix = "aromapacifico-network"
}
run "disabled_vpn" {
  command = plan
  assert {
    condition     = length(aws_vpn_connection.this) == 0 && length(aws_customer_gateway.this) == 0 && length(aws_ec2_transit_gateway_route.collection_center) == 0 && length(aws_ec2_transit_gateway_route_table.this) == 0 && length(aws_ec2_transit_gateway_vpc_attachment_accepter.production) == 0 && length(aws_ec2_transit_gateway_route_table_association.production) == 0 && length(aws_ec2_transit_gateway_route_table_association.vpn) == 0 && length(aws_ec2_transit_gateway_route.production) == 0 && length(aws_ec2_transit_gateway_route.hub_dns) == 0 && length(aws_ec2_transit_gateway_route.hub_return) == 0
    error_message = "No connection input means no hybrid resources."
  }
}
run "cauca_bgp_two_tunnels_and_secret_storage" {
  command = plan
  variables {
    transit_gateway_id = "tgw-0123456789abcdef0"
    connection = {
      production_collection_center_id = "ACOPIO-CAUCA"
      customer_gateway_public_ip      = "192.0.2.1"
      production_attachment_id        = "tgw-attach-00000000000000001"
      tunnel_log_group_arn            = "arn:aws:logs:us-east-1:111122223333:log-group:vpn-fixture"
    }
  }
  assert {
    condition     = aws_customer_gateway.this[0].bgp_asn == "65041" && aws_customer_gateway.this[0].ip_address == var.connection.customer_gateway_public_ip && aws_vpn_connection.this[0].transit_gateway_id == var.transit_gateway_id && !aws_vpn_connection.this[0].static_routes_only
    error_message = "Use the chosen department and BGP through the central TGW."
  }
  assert {
    condition     = aws_vpn_connection.this[0].preshared_key_storage == "SecretsManager" && toset(aws_vpn_connection.this[0].tunnel1_ike_versions) == toset(["ikev2"]) && toset(aws_vpn_connection.this[0].tunnel2_ike_versions) == toset(["ikev2"]) && length(output.vpn.tunnels) == 2 && output.vpn.tunnels[0].outside_ip != output.vpn.tunnels[1].outside_ip
    error_message = "Both tunnels must use IKEv2 and AWS-managed PSK storage."
  }
  assert {
    condition     = toset(keys(output.vpn)) == toset(["id", "customer_gateway_id", "route_table_id", "preshared_key_arn", "tunnels"]) && alltrue([for tunnel in output.vpn.tunnels : !contains(keys(tunnel), "preshared_key")])
    error_message = "The output handoff must not expose keys or full customer gateway XML."
  }
  assert {
    condition     = length(aws_ec2_transit_gateway_route.collection_center) == 2 && toset([for route in aws_ec2_transit_gateway_route.collection_center : route.destination_cidr_block]) == toset(["10.41.3.0/24", "10.41.10.0/24"]) && aws_ec2_transit_gateway_route.production[0].destination_cidr_block == "10.70.0.0/16"
    error_message = "Install only authorized operational prefixes and the production return route."
  }
  assert {
    condition     = aws_ec2_transit_gateway_route_table_association.production[0].transit_gateway_attachment_id == var.connection.production_attachment_id && aws_ec2_transit_gateway_route_table_association.vpn[0].transit_gateway_attachment_id == aws_vpn_connection.this[0].transit_gateway_attachment_id && !aws_ec2_transit_gateway_vpc_attachment_accepter.production[0].transit_gateway_default_route_table_propagation
    error_message = "Associate the production and VPN attachments explicitly without propagation."
  }
}

run "huila_vpn_selection" {
  command = plan
  variables {
    transit_gateway_id           = "tgw-0123456789abcdef0"
    collection_center_department = 42
    connection = {
      production_collection_center_id = "ACOPIO-HUILA"
      customer_gateway_public_ip      = "192.0.2.1"
      production_attachment_id        = "tgw-attach-00000000000000001"
      tunnel_log_group_arn            = "arn:aws:logs:us-east-1:111122223333:log-group:vpn-fixture"
    }
  }
  assert {
    condition     = aws_customer_gateway.this[0].bgp_asn == "65042" && toset([for route in aws_ec2_transit_gateway_route.collection_center : route.destination_cidr_block]) == toset(["10.42.3.0/24", "10.42.10.0/24"])
    error_message = "Department selection must change the ASN and authorized routes without editing resources."
  }
}

run "tolima_vpn_selection" {
  command = plan
  variables {
    transit_gateway_id           = "tgw-0123456789abcdef0"
    collection_center_department = 43
    connection = {
      production_collection_center_id = "ACOPIO-TOLIMA"
      customer_gateway_public_ip      = "192.0.2.1"
      production_attachment_id        = "tgw-attach-00000000000000001"
      tunnel_log_group_arn            = "arn:aws:logs:us-east-1:111122223333:log-group:vpn-fixture"
    }
  }
  assert {
    condition     = aws_customer_gateway.this[0].bgp_asn == "65043" && toset([for route in aws_ec2_transit_gateway_route.collection_center : route.destination_cidr_block]) == toset(["10.43.3.0/24", "10.43.10.0/24"])
    error_message = "Department selection must change the ASN and authorized routes without editing resources."
  }
}

run "reject_private_cpe" {
  command = plan
  variables {
    transit_gateway_id = "tgw-0123456789abcdef0"
    connection = {
      production_collection_center_id = "ACOPIO-CAUCA"
      customer_gateway_public_ip      = "10.41.20.2"
      production_attachment_id        = "tgw-attach-00000000000000001"
      tunnel_log_group_arn            = "arn:aws:logs:us-east-1:111122223333:log-group:vpn-fixture"
    }
  }
  expect_failures = [var.connection]
}
run "hub_dns_routes" {
  command = plan
  variables {
    transit_gateway_id = "tgw-0123456789abcdef0"
    connection = {
      production_collection_center_id = "ACOPIO-CAUCA"
      customer_gateway_public_ip      = "192.0.2.1"
      production_attachment_id        = "tgw-attach-00000000000000001"
      tunnel_log_group_arn            = "arn:aws:logs:us-east-1:111122223333:log-group:vpn-fixture"
    }
    hub_dns = {
      attachment_id  = "tgw-attach-00000000000000003"
      route_table_id = "tgw-rtb-00000000000000004"
      resolver_ips   = ["10.80.40.10", "10.80.140.10"]
    }
  }
  assert {
    condition     = toset([for route in aws_ec2_transit_gateway_route.hub_dns : route.destination_cidr_block]) == toset(["10.80.40.10/32", "10.80.140.10/32"]) && length(aws_ec2_transit_gateway_route.hub_return) == 2
    error_message = "DNS paths must use exact resolver /32s and operational return prefixes."
  }
}

run "reject_enabled_vpn_without_tgw" {
  command = plan
  variables {
    connection = {
      production_collection_center_id = "ACOPIO-CAUCA"
      customer_gateway_public_ip      = "192.0.2.1"
      production_attachment_id        = "tgw-attach-00000000000000001"
      tunnel_log_group_arn            = "arn:aws:logs:us-east-1:111122223333:log-group:vpn-fixture"
    }
  }
  expect_failures = [var.transit_gateway_id]
}
