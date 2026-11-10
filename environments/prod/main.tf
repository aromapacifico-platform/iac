locals {
  ambiente = {
    dev  = "desarrollo"
    test = "pruebas"
    prod = "produccion"
  }

  name_prefix = "aromapacifico-${var.environment}"

  # Mandatory tags of the landing zone. Modules override FincaID, DronID,
  # AcopioID and ViajeID on the resources that belong to one of them.
  default_tags = {
    FincaID     = "GLOBAL"
    DronID      = "NO-APLICA"
    AcopioID    = "MULTICENTRO"
    ViajeID     = "NO-APLICA"
    Ambiente    = local.ambiente[var.environment]
    Propietario = var.owner
    Proyecto    = "AromaPacifico"
  }
}

# Modules are wired here as they land:
#   module "security"       -> planning #23
#   module "ingest", "farm" -> planning #24
#   module "function"       -> planning #25

locals {
  gateway_endpoint_policies = {
    for service, access in var.endpoint_access : service => jsonencode({
      Version = "2012-10-17"
      Statement = [{
        Sid       = "ScopedEnvironmentAccess"
        Effect    = "Allow"
        Principal = { AWS = access.principal_arns }
        Action    = access.actions
        Resource  = access.resource_arns
      }]
    })
  }
}

module "network" {
  source = "../../modules/network"

  name_prefix                  = local.name_prefix
  aws_region                   = var.aws_region
  vpc_cidr                     = var.vpc_cidr
  availability_zones           = var.availability_zones
  gateway_endpoint_policies    = local.gateway_endpoint_policies
  collection_center_department = var.collection_center_department
  transit_gateway_id           = var.transit_gateway_id
  s3_interface = var.s3_interface_security_group_id == null ? null : {
    security_group_id = var.s3_interface_security_group_id
    policy            = local.gateway_endpoint_policies["s3"]
  }
}
