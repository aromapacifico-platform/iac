# Mock-only account, role and attachment identifiers.
mock_provider "aws" {
  override_during = plan
  mock_resource "aws_ec2_transit_gateway" {
    defaults = { id = "tgw-0123456789abcdef0", arn = "arn:aws:ec2:us-east-1:111122223333:transit-gateway/tgw-0123456789abcdef0" }
  }
  mock_data "aws_ec2_transit_gateway" {
    defaults = {
      arn                             = "arn:aws:ec2:us-east-1:111122223333:transit-gateway/tgw-0123456789abcdef0"
      owner_id                        = "111122223333"
      amazon_side_asn                 = 64512
      default_route_table_association = "disable"
      default_route_table_propagation = "disable"
      auto_accept_shared_attachments  = "disable"
    }
  }
  mock_data "aws_ec2_transit_gateway_vpc_attachment" {
    defaults = { vpc_owner_id = "444455556666", transit_gateway_id = "tgw-0123456789abcdef0" }
  }
}
mock_provider "aws" {
  alias           = "foreign"
  override_during = plan
  mock_resource "aws_ec2_transit_gateway" {
    defaults = { id = "tgw-0123456789abcdef0", arn = "arn:aws:ec2:us-east-1:111122223333:transit-gateway/tgw-0123456789abcdef0" }
  }
  mock_data "aws_ec2_transit_gateway" {
    defaults = {
      arn                             = "arn:aws:ec2:us-east-1:111122223333:transit-gateway/tgw-0123456789abcdef0"
      owner_id                        = "111122223333"
      amazon_side_asn                 = 64512
      default_route_table_association = "disable"
      default_route_table_propagation = "disable"
      auto_accept_shared_attachments  = "disable"
    }
  }
  mock_data "aws_ec2_transit_gateway_vpc_attachment" {
    defaults = { vpc_owner_id = "777788889999", transit_gateway_id = "tgw-0123456789abcdef0" }
  }
}
variables {
  create_transit_gateway = true
  network_account_id     = "111122223333"
  network_role_arn       = "arn:aws:iam::111122223333:role/network-fixture"
  production_account_id  = "444455556666"
}
run "central_tgw_without_vpn" {
  command = plan
  assert {
    condition     = aws_ec2_transit_gateway.central[0].amazon_side_asn == 64512 && aws_ec2_transit_gateway.central[0].default_route_table_association == "disable" && aws_ec2_transit_gateway.central[0].default_route_table_propagation == "disable" && aws_ec2_transit_gateway.central[0].auto_accept_shared_attachments == "disable" && !aws_ram_resource_share.production.allow_external_principals && aws_ram_principal_association.production.principal == var.production_account_id && output.vpn == null && length(data.aws_ec2_transit_gateway_vpc_attachment.production) == 0 && length(data.aws_ec2_transit_gateway.existing) == 0
    error_message = "Exactly one central TGW must be explicitly shared to production without implicit routing or a default VPN."
  }
}
run "reject_wrong_network_role" {
  command = plan
  variables { network_role_arn = "arn:aws:iam::444455556666:role/wrong-account" }
  expect_failures = [var.network_role_arn]
}
run "reject_nonproduction_attachment" {
  command = plan
  variables {
    create_transit_gateway      = false
    existing_transit_gateway_id = "tgw-0123456789abcdef0"
    connection = {
      production_collection_center_id = "ACOPIO-CAUCA"
      customer_gateway_public_ip      = "192.0.2.1"
      production_attachment_id        = "tgw-attach-00000000000000001"
      tunnel_log_group_arn            = "arn:aws:logs:us-east-1:111122223333:log-group:vpn-fixture"
    }
  }
  providers       = { aws = aws.foreign }
  expect_failures = [data.aws_ec2_transit_gateway_vpc_attachment.production]
}

run "reuse_existing_central_tgw" {
  command = plan
  variables {
    create_transit_gateway      = false
    existing_transit_gateway_id = "tgw-0123456789abcdef0"
  }
  assert {
    condition     = length(aws_ec2_transit_gateway.central) == 0 && output.transit_gateway_id == var.existing_transit_gateway_id
    error_message = "An existing TGW must keep its lifecycle in its owning state without creating another TGW."
  }
}
run "reject_ambiguous_tgw_ownership" {
  command = plan
  variables { existing_transit_gateway_id = "tgw-0123456789abcdef0" }
  expect_failures = [var.create_transit_gateway]
}

run "production_vpn_handoff" {
  command = plan
  variables {
    create_transit_gateway      = false
    existing_transit_gateway_id = "tgw-0123456789abcdef0"
    connection = {
      production_collection_center_id = "ACOPIO-CAUCA"
      customer_gateway_public_ip      = "192.0.2.1"
      production_attachment_id        = "tgw-attach-00000000000000001"
      tunnel_log_group_arn            = "arn:aws:logs:us-east-1:111122223333:log-group:vpn-fixture"
    }
  }
  assert {
    condition     = output.vpn != null && length(output.vpn.tunnels) == 2
    error_message = "A verified production attachment must wire the central VPN and expose both tunnel handoffs."
  }
}

run "reject_department_mismatch" {
  command = plan
  variables {
    create_transit_gateway       = false
    existing_transit_gateway_id  = "tgw-0123456789abcdef0"
    collection_center_department = 42
    connection = {
      production_collection_center_id = "ACOPIO-CAUCA"
      customer_gateway_public_ip      = "192.0.2.1"
      production_attachment_id        = "tgw-attach-00000000000000001"
      tunnel_log_group_arn            = "arn:aws:logs:us-east-1:111122223333:log-group:vpn-fixture"
    }
  }
  expect_failures = [var.connection]
}
