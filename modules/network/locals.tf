locals {
  # Fixed subnet numbers from the approved address plan.
  subnet_numbers = {
    ingest_telemetry = 1
    ingest_drone     = 2
    app              = 10
    data             = 20
    storage          = 30
    admin            = 40
    public_query     = 50
  }

  # The second availability zone uses subnet numbers offset by 100.
  zones = {
    az_a = {
      availability_zone = try(var.availability_zones[0], null)
      offset            = 0
    }
    az_b = {
      availability_zone = try(var.availability_zones[1], null)
      offset            = 100
    }
  }

  vpc_name = "${var.name_prefix}-vpc"

  subnets = merge([
    for zone_key, zone in local.zones : {
      for category, subnet_number in local.subnet_numbers :
      "${category}_${zone_key}" => {
        name = "${var.name_prefix}-${replace(category, "_", "-")}-${zone_key}"

        cidr_block = cidrsubnet(
          var.vpc_cidr,
          8,
          subnet_number + zone.offset
        )

        availability_zone = zone.availability_zone
        category          = category
      }
    }
  ]...)

  internet_gateway_name = "${var.name_prefix}-igw"

  route_table_names = {
    for key, subnet in local.subnets :
    key => "${subnet.name}-rt"
  }

  public_subnets = {
    for key, subnet in local.subnets :
    key => subnet
    if subnet.category == "public_query"
  }

  gateway_endpoints = {
    for service in ["s3", "dynamodb"] :
    service => {
      name         = "${var.name_prefix}-${service}-gateway"
      service_name = "com.amazonaws.${var.aws_region}.${service}"
    }
  }

  gateway_endpoint_route_table_ids = [
    for key, route_table in aws_route_table.this :
    route_table.id
    if local.subnets[key].category != "public_query"
  ]

  collection_center_names = {
    "41" = "CAUCA"
    "42" = "HUILA"
    "43" = "TOLIMA"
  }

  collection_center = {
    id = "ACOPIO-${lookup(local.collection_center_names, tostring(var.collection_center_department), "INVALID")}"

    cidr    = "10.${var.collection_center_department}.0.0/16"
    bgp_asn = 65000 + var.collection_center_department

    operational_cidrs = {
      logistics = "10.${var.collection_center_department}.3.0/24"
      servers   = "10.${var.collection_center_department}.10.0/24"
    }
  }
}
locals {
  internal_subnets = { for key, subnet in local.subnets : key => subnet if subnet.category != "public_query" }
  hybrid_routes = var.transit_gateway_id == null ? {} : merge([
    for key, subnet in local.internal_subnets : {
      for purpose, cidr in local.collection_center.operational_cidrs :
      "${key}_${purpose}" => { subnet_key = key, cidr = cidr }
    }
  ]...)
}
