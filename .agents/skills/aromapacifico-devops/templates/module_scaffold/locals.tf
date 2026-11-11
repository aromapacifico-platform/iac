locals {
  common_tags = merge(var.additional_tags, { ManagedBy = "Terraform" })
}
