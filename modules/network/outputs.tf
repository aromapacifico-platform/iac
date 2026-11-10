output "vpc_id" {
  description = "ID of the environment VPC."
  value       = aws_vpc.this.id
}

output "subnet_ids" {
  description = "Subnet IDs indexed by category and availability zone."
  value = {
    for key, subnet in aws_subnet.this :
    key => subnet.id
  }
}

output "subnet_cidrs" {
  description = "Subnet CIDRs indexed by category and availability zone."
  value = {
    for key, subnet in local.subnets :
    key => subnet.cidr_block
  }
}

output "route_table_ids" {
  description = "Route table IDs indexed by category and availability zone."
  value = {
    for key, route_table in aws_route_table.this :
    key => route_table.id
  }
}

output "gateway_endpoint_ids" {
  description = "Gateway endpoint IDs indexed by service."
  value = {
    for service, endpoint in aws_vpc_endpoint.gateway :
    service => endpoint.id
  }
}

output "gateway_endpoint_prefix_list_ids" {
  description = "Service prefix list IDs for security group integration."
  value = {
    for service, endpoint in aws_vpc_endpoint.gateway :
    service => endpoint.prefix_list_id
  }
}

output "collection_center" {
  description = "Selected collection center identity, address space, BGP ASN and operational prefixes."
  value       = local.collection_center
}
output "private_subnet_ids" {
  description = "Internal subnet IDs for the security module."
  value       = [for key in sort(keys(local.internal_subnets)) : aws_subnet.this[key].id]
}

output "public_subnet_ids" {
  description = "Public query subnet IDs for the security module."
  value       = [for key in sort(keys(local.public_subnets)) : aws_subnet.this[key].id]
}

output "function_subnet_ids" {
  description = "Drone ingestion subnets for the focus function VPC configuration."
  value       = [aws_subnet.this["ingest_drone_az_a"].id, aws_subnet.this["ingest_drone_az_b"].id]
}

output "transit_gateway_attachment_id" {
  description = "Production attachment to accept and associate in the central Network state."
  value       = one(aws_ec2_transit_gateway_vpc_attachment.this[*].id)
}

output "s3_interface_endpoint" {
  description = "Non-secret endpoint identity and DNS records for hybrid S3 client configuration."
  value = var.s3_interface == null ? null : {
    id          = aws_vpc_endpoint.s3_interface[0].id
    dns_entries = aws_vpc_endpoint.s3_interface[0].dns_entry
  }
}
