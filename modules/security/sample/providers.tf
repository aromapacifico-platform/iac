provider "aws" {
  alias  = "principal"
  region = var.aws_region

  default_tags {
    tags = {
      FincaID     = "GLOBAL"
      DronID      = "NO-APLICA"
      AcopioID    = "MULTICENTRO"
      ViajeID     = "NO-APLICA"
      Ambiente    = "desarrollo"
      Propietario = "devops-fnc"
      Proyecto    = "AromaPacifico"
    }
  }
}
