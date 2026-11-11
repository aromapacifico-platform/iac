locals {
  client      = var.client
  project     = var.project
  environment = var.environment
  ambiente    = { dev = "desarrollo", test = "pruebas", prod = "produccion" }
  default_tags = merge(var.additional_tags, {
    FincaID  = "GLOBAL", DronID = "NO-APLICA", AcopioID = "MULTICENTRO", ViajeID = "NO-APLICA",
    Ambiente = local.ambiente[var.environment], Propietario = "devops-fnc", Proyecto = "AromaPacifico"
  })
}
