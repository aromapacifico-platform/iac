provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      FincaID     = "GLOBAL"
      DronID      = "NO-APLICA"
      AcopioID    = "MULTICENTRO"
      ViajeID     = "NO-APLICA"
      Ambiente    = local.ambiente[var.environment]
      Propietario = "devops-fnc"
      Proyecto    = "AromaPacifico"
    }
  }
}
