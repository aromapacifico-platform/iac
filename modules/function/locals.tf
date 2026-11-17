# ==============================================================================
# Local Values & Name Conventions (PC-IAC-003, PC-IAC-004, PC-IAC-009, PC-IAC-012)
# ==============================================================================

locals {
  # Root-built physical naming prefix per PC-IAC-025
  name_prefix = var.name_prefix

  # Physical resource names adhering strictly to <= 28 characters
  bucket_name          = "${local.name_prefix}-s3-focus-conf"
  dlq_name             = "${local.name_prefix}-sqs-focus-dlq"
  lambda_function_name = "${local.name_prefix}-fn-focus-conf"

  # AWS Context
  account_id = data.aws_caller_identity.current.account_id
  aws_region = data.aws_region.current.region
  partition  = data.aws_partition.current.partition

  # Common Tagging (PC-IAC-004 Layer 2)
  common_tags = merge(
    var.additional_tags,
    {
      Module     = "modules/function"
      Component  = "FocusConfirmation"
      ManagedBy  = "Terraform"
      Challenge  = "FNC2026-AromaPacifico"
      Disparador = "S3-EventNotification"
    }
  )
}
