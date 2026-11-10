resource "aws_vpc" "this" {
  cidr_block = var.vpc_cidr

  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = local.vpc_name
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_subnet" "this" {
  for_each = local.subnets

  vpc_id            = aws_vpc.this.id
  cidr_block        = each.value.cidr_block
  availability_zone = each.value.availability_zone

  map_public_ip_on_launch = false

  tags = {
    Name     = each.value.name
    Category = each.value.category
  }
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name = local.internet_gateway_name
  }
}

resource "aws_route_table" "this" {
  for_each = local.subnets

  vpc_id = aws_vpc.this.id

  tags = {
    Name     = local.route_table_names[each.key]
    Category = each.value.category
  }
}

resource "aws_route_table_association" "this" {
  for_each = local.subnets

  subnet_id      = aws_subnet.this[each.key].id
  route_table_id = aws_route_table.this[each.key].id
}

resource "aws_route" "public_internet" {
  for_each = local.public_subnets

  route_table_id         = aws_route_table.this[each.key].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this.id
}

resource "aws_vpc_endpoint" "gateway" {
  for_each = local.gateway_endpoints

  vpc_id            = aws_vpc.this.id
  service_name      = each.value.service_name
  vpc_endpoint_type = "Gateway"

  route_table_ids = local.gateway_endpoint_route_table_ids
  policy          = var.gateway_endpoint_policies[each.key]

  tags = {
    Name = each.value.name
  }
}
# The TGW is owned and shared by the central Network account, never by this VPC.
resource "aws_ec2_transit_gateway_vpc_attachment" "this" {
  count = var.transit_gateway_id == null ? 0 : 1

  transit_gateway_id = var.transit_gateway_id
  vpc_id             = aws_vpc.this.id
  subnet_ids         = [aws_subnet.this["admin_az_a"].id, aws_subnet.this["admin_az_b"].id]
  dns_support        = "enable"

  # AWS ignores these flags on RAM-shared attachments. The central owner
  # enforces disabled defaults and explicit associations in its own state.
  transit_gateway_default_route_table_association = false
  transit_gateway_default_route_table_propagation = false

  tags = { Name = "${var.name_prefix}-tgw", AcopioID = local.collection_center.id }
}

resource "aws_route" "collection_center" {
  for_each = local.hybrid_routes

  route_table_id         = aws_route_table.this[each.value.subnet_key].id
  destination_cidr_block = each.value.cidr
  transit_gateway_id     = var.transit_gateway_id

  depends_on = [aws_ec2_transit_gateway_vpc_attachment.this]
}

resource "aws_vpc_endpoint" "s3_interface" {
  count = var.s3_interface == null ? 0 : 1

  vpc_id              = aws_vpc.this.id
  service_name        = "com.amazonaws.${var.aws_region}.s3"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_subnet.this["storage_az_a"].id, aws_subnet.this["storage_az_b"].id]
  security_group_ids  = [var.s3_interface.security_group_id]
  policy              = var.s3_interface.policy
  private_dns_enabled = false

  # Endpoint-specific DNS avoids capturing in-VPC traffic away from the gateway.
  tags = { Name = "${var.name_prefix}-s3-interface" }
}
