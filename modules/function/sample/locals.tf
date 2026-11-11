# ==============================================================================
# Sample Transformation Layer (PC-IAC-025, PC-IAC-026)
# ==============================================================================

locals {
  # Physical name constructed by Root/Fixture (PC-IAC-025)
  name_prefix = "${var.client}-${var.project}-${var.environment}"

  # Merged tags
  common_tags = merge(
    var.additional_tags,
    {
      Environment = var.environment
      Fixture     = "modules/function/sample"
    }
  )
}
