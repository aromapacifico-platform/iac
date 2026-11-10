# One TGW for the organization. Workload environments only receive its ID.
resource "aws_ec2_transit_gateway" "central" {
  count                           = var.create_transit_gateway ? 1 : 0
  description                     = "AromaPacifico central hybrid network"
  amazon_side_asn                 = 64512
  auto_accept_shared_attachments  = "disable"
  default_route_table_association = "disable"
  default_route_table_propagation = "disable"
  vpn_ecmp_support                = "disable"
  tags                            = { Name = "aromapacifico-network-tgw" }
  lifecycle {
    prevent_destroy = true
  }
}
resource "aws_ram_resource_share" "production" {
  name                      = "aromapacifico-network-prod"
  allow_external_principals = false
}
resource "aws_ram_resource_association" "tgw" {
  resource_arn       = local.transit_gateway_arn
  resource_share_arn = aws_ram_resource_share.production.arn
}
resource "aws_ram_principal_association" "production" {
  principal          = var.production_account_id
  resource_share_arn = aws_ram_resource_share.production.arn
}
module "hybrid" {
  source                       = "../../modules/network/modules/hybrid"
  name_prefix                  = "aromapacifico-network"
  transit_gateway_id           = local.transit_gateway_id
  collection_center_department = var.collection_center_department
  connection                   = var.connection
  depends_on                   = [data.aws_ec2_transit_gateway_vpc_attachment.production]
  hub_dns                      = var.hub_dns
}

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
locals {
  collection_center_id = "ACOPIO-${lookup({ "41" = "CAUCA", "42" = "HUILA", "43" = "TOLIMA" }, tostring(var.collection_center_department), "INVALID")}"
  transit_gateway_id   = var.create_transit_gateway ? aws_ec2_transit_gateway.central[0].id : try(data.aws_ec2_transit_gateway.existing[0].id, null)
  transit_gateway_arn  = var.create_transit_gateway ? aws_ec2_transit_gateway.central[0].arn : try(data.aws_ec2_transit_gateway.existing[0].arn, null)
}
