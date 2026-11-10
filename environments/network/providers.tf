provider "aws" {
  region              = "us-east-1"
  allowed_account_ids = [var.network_account_id]
  assume_role {
    role_arn = var.network_role_arn
  }
  default_tags {
    tags = {
      FincaID     = "GLOBAL"
      DronID      = "NO-APLICA"
      AcopioID    = "MULTICENTRO"
      ViajeID     = "NO-APLICA"
      Ambiente    = "produccion"
      Propietario = "devops-fnc"
      Proyecto    = "AromaPacifico"
    }
  }
}
