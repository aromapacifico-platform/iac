locals {
  tags       = merge(var.additional_tags, { Name = var.thing_name, FincaID = var.farm_id, ManagedBy = "Terraform" })
  attributes = { FincaID = var.farm_id }
}
