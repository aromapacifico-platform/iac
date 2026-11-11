output "name_prefix" {
  description = "Prefix for resource names in this environment."
  value       = local.name_prefix
}

output "network_inputs" {
  description = "Legacy addressing metadata; collection_center_cidrs does not enable routing."
  value = {
    vpc_cidr                = var.vpc_cidr
    availability_zones      = var.availability_zones
    collection_center_cidrs = var.collection_center_cidrs
  }
}

output "network" {
  description = "Network contracts consumed by security, workloads and the central Network root."
  value = {
    vpc_id                           = module.network.vpc_id
    subnet_ids                       = module.network.subnet_ids
    subnet_cidrs                     = module.network.subnet_cidrs
    private_subnet_ids               = module.network.private_subnet_ids
    public_subnet_ids                = module.network.public_subnet_ids
    function_subnet_ids              = module.network.function_subnet_ids
    route_table_ids                  = module.network.route_table_ids
    gateway_endpoint_ids             = module.network.gateway_endpoint_ids
    gateway_endpoint_prefix_list_ids = module.network.gateway_endpoint_prefix_list_ids
    collection_center                = module.network.collection_center
    transit_gateway_attachment_id    = module.network.transit_gateway_attachment_id
    s3_interface_endpoint            = module.network.s3_interface_endpoint
  }
}

output "ingest" {
  description = "Reception contracts; no alert or persistence ACK SLA is implied."
  value = {
    tables          = module.ingest.tables
    mqtt_topics     = module.ingest.mqtt_topics
    config_topic    = module.ingest.config_topic
    error_queue_url = module.ingest.error_queue_url
  }
}
output "farm" {
  description = "Single pattern farm identity and certificate ARN."
  value       = { thing_name = module.farm.thing_name, certificate_arn = module.farm.certificate_arn }
}
