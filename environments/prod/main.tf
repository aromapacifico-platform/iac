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
#   module "network"        -> planning #22
#   module "security"       -> planning #23
#   module "ingest", "farm" -> planning #24
#   module "focus_function" -> planning #25
