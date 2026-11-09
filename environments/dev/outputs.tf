output "name_prefix" {
  description = "Prefix for resource names in this environment."
  value       = local.name_prefix
}

output "network_inputs" {
  description = "Addressing inputs the network module consumes."
  value = {
    vpc_cidr                = var.vpc_cidr
    availability_zones      = var.availability_zones
    collection_center_cidrs = var.collection_center_cidrs
  }
}
