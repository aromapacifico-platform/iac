locals {
  default_tags = {
    FincaID  = "GLOBAL", DronID = "NO-APLICA", AcopioID = "MULTICENTRO", ViajeID = "NO-APLICA",
    Ambiente = "desarrollo", Propietario = "devops-fnc", Proyecto = "AromaPacifico"
  }
  name_prefix = "${var.client}-${var.project}-${var.environment}"
  thing_name  = "${local.name_prefix}-thing-${lower(var.farm_id)}"
}
