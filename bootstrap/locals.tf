locals {
  ambiente = {
    dev  = "desarrollo"
    test = "pruebas"
    prod = "produccion"
  }

  bucket_name = coalesce(var.state_bucket_name, "aromapacifico-tfstate-${var.environment}")
}
