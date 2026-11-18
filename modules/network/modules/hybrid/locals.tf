locals {
  center_id = "ACOPIO-${lookup({ "41" = "CAUCA", "42" = "HUILA", "43" = "TOLIMA" }, tostring(var.collection_center_department), "INVALID")}"
  operational_cidrs = {
    logistics = "10.${var.collection_center_department}.3.0/24"
    servers   = "10.${var.collection_center_department}.10.0/24"
  }
}
