# External data lookups isolated in data.tf per PC-IAC-011.
# A profile label is not evidence of account ownership. Verify the supplied
# cross-account attachment before allowing the central state to accept it.
data "aws_ec2_transit_gateway_vpc_attachment" "production" {
  count = var.connection == null ? 0 : 1
  id    = var.connection.production_attachment_id
  lifecycle {
    postcondition {
      condition     = self.vpc_owner_id == var.production_account_id && self.transit_gateway_id == local.transit_gateway_id
      error_message = "The supplied attachment must belong to the production account and central TGW."
    }
  }
}

data "aws_ec2_transit_gateway" "existing" {
  count = var.existing_transit_gateway_id == null ? 0 : 1
  id    = var.existing_transit_gateway_id
  lifecycle {
    postcondition {
      condition     = self.owner_id == var.network_account_id && self.amazon_side_asn == 64512 && self.default_route_table_association == "disable" && self.default_route_table_propagation == "disable" && self.auto_accept_shared_attachments == "disable"
      error_message = "The existing TGW must be owned by Network, use ASN 64512 and disable default association, propagation and automatic attachment acceptance."
    }
  }
}
