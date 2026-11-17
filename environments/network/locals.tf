locals {
  name_prefix          = "${var.project}-${var.environment}"
  collection_center_id = "ACOPIO-${lookup({ "41" = "CAUCA", "42" = "HUILA", "43" = "TOLIMA" }, tostring(var.collection_center_department), "INVALID")}"
  transit_gateway_id   = var.create_transit_gateway ? aws_ec2_transit_gateway.central[0].id : try(data.aws_ec2_transit_gateway.existing[0].id, null)
  transit_gateway_arn  = var.create_transit_gateway ? aws_ec2_transit_gateway.central[0].arn : try(data.aws_ec2_transit_gateway.existing[0].arn, null)

  default_tags = {
    FincaID     = "GLOBAL"
    DronID      = "NO-APLICA"
    AcopioID    = "MULTICENTRO"
    ViajeID     = "NO-APLICA"
    Ambiente    = "produccion"
    Propietario = var.owner
    Proyecto    = "AromaPacifico"
  }
}
