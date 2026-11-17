output "vpc_id" {
  description = "VPC ID created by the network sample."
  value       = module.network.vpc_id
}

output "private_subnet_ids" {
  description = "Private subnet IDs created by the network sample."
  value       = module.network.private_subnet_ids
}

output "public_subnet_ids" {
  description = "Public query subnet IDs created by the network sample."
  value       = module.network.public_subnet_ids
}
