mock_provider "aws" {
  override_during = plan
  mock_resource "aws_ec2_transit_gateway_vpc_attachment" {
    defaults = { id = "tgw-attach-0123456789abcdef0" }
  }
}

variables {
  name_prefix        = "aromapacifico-prod"
  vpc_cidr           = "10.70.0.0/16"
  aws_region         = "us-east-1"
  availability_zones = ["us-east-1a", "us-east-1b"]

  # Test fixtures only. These are not deployment policies.
  gateway_endpoint_policies = {
    for service in ["s3", "dynamodb"] : service => jsonencode({
      Version = "2012-10-17"
      Statement = [{
        Sid       = "DenyAllTestFixture"
        Effect    = "Deny"
        Principal = "*"
        Action    = "*"
        Resource  = "*"
      }]
    })
  }
}

run "production_network_plan" {
  command = plan

  assert {
    condition = tomap(output.subnet_cidrs) == tomap({
      ingest_telemetry_az_a = "10.70.1.0/24"
      ingest_telemetry_az_b = "10.70.101.0/24"
      ingest_drone_az_a     = "10.70.2.0/24"
      ingest_drone_az_b     = "10.70.102.0/24"
      app_az_a              = "10.70.10.0/24"
      app_az_b              = "10.70.110.0/24"
      data_az_a             = "10.70.20.0/24"
      data_az_b             = "10.70.120.0/24"
      storage_az_a          = "10.70.30.0/24"
      storage_az_b          = "10.70.130.0/24"
      admin_az_a            = "10.70.40.0/24"
      admin_az_b            = "10.70.140.0/24"
      public_query_az_a     = "10.70.50.0/24"
      public_query_az_b     = "10.70.150.0/24"
    })
    error_message = "Subnet CIDRs must match the approved production address plan."
  }

  assert {
    condition = (
      length(aws_subnet.this) == 14 &&
      length(aws_route_table.this) == 14 &&
      length(aws_route_table_association.this) == 14
    )
    error_message = "The module must declare 14 subnets, route tables and associations."
  }

  assert {
    condition = (
      toset(keys(aws_route.public_internet)) ==
      toset(["public_query_az_a", "public_query_az_b"]) &&
      alltrue([
        for route in values(aws_route.public_internet) :
        route.destination_cidr_block == "0.0.0.0/0"
      ])
    )
    error_message = "Only public query subnets may have a direct default route to the internet."
  }

  assert {
    condition = alltrue([
      for subnet in values(aws_subnet.this) :
      subnet.map_public_ip_on_launch == false
    ])
    error_message = "Automatic public IP assignment must remain disabled."
  }

  assert {
    condition = (
      toset(keys(aws_vpc_endpoint.gateway)) == toset(["s3", "dynamodb"]) &&
      aws_vpc_endpoint.gateway["s3"].vpc_endpoint_type == "Gateway" &&
      aws_vpc_endpoint.gateway["dynamodb"].vpc_endpoint_type == "Gateway" &&
      aws_vpc_endpoint.gateway["s3"].service_name == "com.amazonaws.us-east-1.s3" &&
      aws_vpc_endpoint.gateway["dynamodb"].service_name == "com.amazonaws.us-east-1.dynamodb"
    )
    error_message = "S3 and DynamoDB must use regional gateway endpoints."
  }
}

run "development_address_plan" {
  command = plan

  variables {
    name_prefix = "aromapacifico-dev"
    vpc_cidr    = "10.50.0.0/16"
  }

  assert {
    condition = tomap({
      for key, cidr in output.subnet_cidrs :
      key => replace(cidr, "10.50.", "10.70.")
    }) == tomap(run.production_network_plan.subnet_cidrs)
    error_message = "Development must preserve the approved subnet layout using 10.50.0.0/16."
  }
}

run "test_address_plan" {
  command = plan

  variables {
    name_prefix = "aromapacifico-test"
    vpc_cidr    = "10.60.0.0/16"
  }

  assert {
    condition = tomap({
      for key, cidr in output.subnet_cidrs :
      key => replace(cidr, "10.60.", "10.70.")
    }) == tomap(run.production_network_plan.subnet_cidrs)
    error_message = "Test must preserve the approved subnet layout using 10.60.0.0/16."
  }
}

run "cauca_collection_center" {
  command = plan

  assert {
    condition = (
      output.collection_center.id == "ACOPIO-CAUCA" &&
      output.collection_center.cidr == "10.41.0.0/16" &&
      output.collection_center.bgp_asn == 65041 &&
      output.collection_center.operational_cidrs.logistics == "10.41.3.0/24" &&
      output.collection_center.operational_cidrs.servers == "10.41.10.0/24"
    )
    error_message = "The default collection center must match the approved Cauca pattern."
  }
}

run "huila_collection_center" {
  command = plan

  variables {
    collection_center_department = 42
  }

  assert {
    condition = (
      output.collection_center.id == "ACOPIO-HUILA" &&
      output.collection_center.cidr == "10.42.0.0/16" &&
      output.collection_center.bgp_asn == 65042 &&
      output.collection_center.operational_cidrs.logistics == "10.42.3.0/24" &&
      output.collection_center.operational_cidrs.servers == "10.42.10.0/24"
    )
    error_message = "Selecting department 42 must produce the approved Huila pattern."
  }
}

run "tolima_collection_center" {
  command = plan

  variables {
    collection_center_department = 43
  }

  assert {
    condition = (
      output.collection_center.id == "ACOPIO-TOLIMA" &&
      output.collection_center.cidr == "10.43.0.0/16" &&
      output.collection_center.bgp_asn == 65043 &&
      output.collection_center.operational_cidrs.logistics == "10.43.3.0/24" &&
      output.collection_center.operational_cidrs.servers == "10.43.10.0/24"
    )
    error_message = "Selecting department 43 must produce the approved Tolima pattern."
  }
}

run "gateway_associations_and_disabled_hybrid" {
  command = plan
  assert {
    condition     = length(aws_ec2_transit_gateway_vpc_attachment.this) == 0 && length(aws_route.collection_center) == 0 && length(aws_vpc_endpoint.s3_interface) == 0
    error_message = "Disabled hybrid access must create no attachment, collection center routes or interface endpoint."
  }
  assert {
    condition = alltrue([for endpoint in aws_vpc_endpoint.gateway :
      toset(endpoint.route_table_ids) == toset([for key, rt in aws_route_table.this : rt.id if !startswith(key, "public_query_")])
    ])
    error_message = "Gateway endpoints must associate with all twelve internal tables and no public tables."
  }
  assert {
    condition = alltrue([for key, association in aws_route_table_association.this :
      association.subnet_id == aws_subnet.this[key].id && association.route_table_id == aws_route_table.this[key].id
    ])
    error_message = "Each subnet must retain its own route table association."
  }
  assert {
    condition = alltrue([for center in [41, 42, 43] :
      !startswith(var.vpc_cidr, "10.${center}.") && alltrue([for cidr in values(output.subnet_cidrs) : !startswith(cidr, "10.${center}.")])
    ])
    error_message = "The environment and its subnets must not overlap any collection center."
  }
}

run "production_hybrid_routes_and_s3_interface" {
  command = plan
  variables {
    transit_gateway_id = "tgw-0123456789abcdef0"
    s3_interface = {
      security_group_id = "sg-0123456789abcdef0"
      policy            = "{\"Statement\":[{\"Effect\":\"Deny\",\"Principal\":\"*\",\"Action\":\"*\",\"Resource\":\"*\"}]}"
    }
  }
  assert {
    condition = length(aws_route.collection_center) == 24 && alltrue([
      for key, route in aws_route.collection_center :
      contains(["10.41.3.0/24", "10.41.10.0/24"], route.destination_cidr_block) &&
      route.transit_gateway_id == var.transit_gateway_id && !startswith(key, "public_query_")
    ])
    error_message = "Only the two operational /24s may be installed in twelve internal tables."
  }
  assert {
    condition = (
      toset(aws_ec2_transit_gateway_vpc_attachment.this[0].subnet_ids) == toset([aws_subnet.this["admin_az_a"].id, aws_subnet.this["admin_az_b"].id]) &&
      !aws_ec2_transit_gateway_vpc_attachment.this[0].transit_gateway_default_route_table_association &&
      !aws_ec2_transit_gateway_vpc_attachment.this[0].transit_gateway_default_route_table_propagation
    )
    error_message = "The TGW attachment must use both admin subnets without default association/propagation."
  }
  assert {
    condition = (
      aws_vpc_endpoint.s3_interface[0].vpc_endpoint_type == "Interface" &&
      !aws_vpc_endpoint.s3_interface[0].private_dns_enabled &&
      toset(aws_vpc_endpoint.s3_interface[0].subnet_ids) == toset([aws_subnet.this["storage_az_a"].id, aws_subnet.this["storage_az_b"].id]) &&
      toset(aws_vpc_endpoint.s3_interface[0].security_group_ids) == toset([var.s3_interface.security_group_id])
    )
    error_message = "Hybrid S3 must use both storage subnets and the supplied security SG without changing VPC S3 DNS."
  }
}

run "reject_unapproved_or_overlapping_cidr" {
  command = plan
  variables { vpc_cidr = "10.41.0.0/16" }
  expect_failures = [var.vpc_cidr]
}
run "reject_department" {
  command = plan
  variables { collection_center_department = 44 }
  expect_failures = [var.collection_center_department]
}
run "reject_duplicate_zones" {
  command = plan
  variables { availability_zones = ["us-east-1a", "us-east-1a"] }
  expect_failures = [var.availability_zones]
}
run "reject_dev_hybrid" {
  command = plan
  variables {
    vpc_cidr           = "10.50.0.0/16"
    transit_gateway_id = "tgw-0123456789abcdef0"
  }
  expect_failures = [var.transit_gateway_id]
}
run "reject_test_hybrid" {
  command = plan
  variables {
    vpc_cidr           = "10.60.0.0/16"
    transit_gateway_id = "tgw-0123456789abcdef0"
  }
  expect_failures = [var.transit_gateway_id]
}
run "reject_endpoint_services" {
  command = plan
  variables { gateway_endpoint_policies = { s3 = "{}" } }
  expect_failures = [var.gateway_endpoint_policies]
}
run "reject_endpoint_json" {
  command = plan
  variables { gateway_endpoint_policies = { s3 = "not-json", dynamodb = "{}" } }
  expect_failures = [var.gateway_endpoint_policies]
}
run "reject_interface_security_contract" {
  command = plan
  variables { s3_interface = { security_group_id = "invalid", policy = "{}" } }
  expect_failures = [var.s3_interface]
}

# Stable, distinct fixture IDs make association checks evaluable during plan.
override_resource {
  target          = aws_subnet.this["ingest_telemetry_az_a"]
  override_during = plan
  values          = { id = "subnet-00000000000000001" }
}
override_resource {
  target          = aws_route_table.this["ingest_telemetry_az_a"]
  override_during = plan
  values          = { id = "rtb-00000000000000001" }
}
override_resource {
  target          = aws_subnet.this["ingest_telemetry_az_b"]
  override_during = plan
  values          = { id = "subnet-00000000000000002" }
}
override_resource {
  target          = aws_route_table.this["ingest_telemetry_az_b"]
  override_during = plan
  values          = { id = "rtb-00000000000000002" }
}
override_resource {
  target          = aws_subnet.this["ingest_drone_az_a"]
  override_during = plan
  values          = { id = "subnet-00000000000000003" }
}
override_resource {
  target          = aws_route_table.this["ingest_drone_az_a"]
  override_during = plan
  values          = { id = "rtb-00000000000000003" }
}
override_resource {
  target          = aws_subnet.this["ingest_drone_az_b"]
  override_during = plan
  values          = { id = "subnet-00000000000000004" }
}
override_resource {
  target          = aws_route_table.this["ingest_drone_az_b"]
  override_during = plan
  values          = { id = "rtb-00000000000000004" }
}
override_resource {
  target          = aws_subnet.this["app_az_a"]
  override_during = plan
  values          = { id = "subnet-00000000000000005" }
}
override_resource {
  target          = aws_route_table.this["app_az_a"]
  override_during = plan
  values          = { id = "rtb-00000000000000005" }
}
override_resource {
  target          = aws_subnet.this["app_az_b"]
  override_during = plan
  values          = { id = "subnet-00000000000000006" }
}
override_resource {
  target          = aws_route_table.this["app_az_b"]
  override_during = plan
  values          = { id = "rtb-00000000000000006" }
}
override_resource {
  target          = aws_subnet.this["data_az_a"]
  override_during = plan
  values          = { id = "subnet-00000000000000007" }
}
override_resource {
  target          = aws_route_table.this["data_az_a"]
  override_during = plan
  values          = { id = "rtb-00000000000000007" }
}
override_resource {
  target          = aws_subnet.this["data_az_b"]
  override_during = plan
  values          = { id = "subnet-00000000000000008" }
}
override_resource {
  target          = aws_route_table.this["data_az_b"]
  override_during = plan
  values          = { id = "rtb-00000000000000008" }
}
override_resource {
  target          = aws_subnet.this["storage_az_a"]
  override_during = plan
  values          = { id = "subnet-00000000000000009" }
}
override_resource {
  target          = aws_route_table.this["storage_az_a"]
  override_during = plan
  values          = { id = "rtb-00000000000000009" }
}
override_resource {
  target          = aws_subnet.this["storage_az_b"]
  override_during = plan
  values          = { id = "subnet-0000000000000000a" }
}
override_resource {
  target          = aws_route_table.this["storage_az_b"]
  override_during = plan
  values          = { id = "rtb-0000000000000000a" }
}
override_resource {
  target          = aws_subnet.this["admin_az_a"]
  override_during = plan
  values          = { id = "subnet-0000000000000000b" }
}
override_resource {
  target          = aws_route_table.this["admin_az_a"]
  override_during = plan
  values          = { id = "rtb-0000000000000000b" }
}
override_resource {
  target          = aws_subnet.this["admin_az_b"]
  override_during = plan
  values          = { id = "subnet-0000000000000000c" }
}
override_resource {
  target          = aws_route_table.this["admin_az_b"]
  override_during = plan
  values          = { id = "rtb-0000000000000000c" }
}
override_resource {
  target          = aws_subnet.this["public_query_az_a"]
  override_during = plan
  values          = { id = "subnet-0000000000000000d" }
}
override_resource {
  target          = aws_route_table.this["public_query_az_a"]
  override_during = plan
  values          = { id = "rtb-0000000000000000d" }
}
override_resource {
  target          = aws_subnet.this["public_query_az_b"]
  override_during = plan
  values          = { id = "subnet-0000000000000000e" }
}
override_resource {
  target          = aws_route_table.this["public_query_az_b"]
  override_during = plan
  values          = { id = "rtb-0000000000000000e" }
}

run "reject_zone_from_another_region" {
  command = plan
  variables { availability_zones = ["us-east-1a", "us-west-2b"] }
  expect_failures = [var.availability_zones]
}
run "reject_missing_zone" {
  command = plan
  variables { availability_zones = ["us-east-1a"] }
  expect_failures = [var.availability_zones]
}
