# Provider configuration for sample fixture (PC-IAC-004, PC-IAC-005, PC-IAC-006)

provider "aws" {
  alias  = "principal"
  region = var.aws_region

  default_tags {
    tags = {
      FincaID     = "GLOBAL"
      DronID      = "NO-APLICA"
      AcopioID    = "MULTICENTRO"
      ViajeID     = "NO-APLICA"
      Ambiente    = var.environment
      Propietario = "devops-fnc"
      Proyecto    = "AromaPacifico"
    }
  }
}
