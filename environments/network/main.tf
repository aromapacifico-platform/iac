# One TGW for the organization. Workload environments only receive its ID.
resource "aws_ec2_transit_gateway" "central" {
  count                           = var.create_transit_gateway ? 1 : 0
  description                     = "AromaPacifico central hybrid network"
  amazon_side_asn                 = 64512
  auto_accept_shared_attachments  = "disable"
  default_route_table_association = "disable"
  default_route_table_propagation = "disable"
  vpn_ecmp_support                = "disable"
  tags                            = { Name = "${local.name_prefix}-tgw" }
  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_ram_resource_share" "production" {
  name                      = "${local.name_prefix}-prod"
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
  name_prefix                  = local.name_prefix
  transit_gateway_id           = local.transit_gateway_id
  collection_center_department = var.collection_center_department
  connection                   = var.connection
  depends_on                   = [data.aws_ec2_transit_gateway_vpc_attachment.production]
  hub_dns                      = var.hub_dns
}
