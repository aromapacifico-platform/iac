# ==============================================================================
# Local Values & Name Conventions (PC-IAC-003, PC-IAC-004, PC-IAC-009, PC-IAC-012)
# ==============================================================================

locals {
  # Physical naming prefix: ${client}-${project}-${environment}
  name_prefix = var.name_prefix != "" ? var.name_prefix : "${var.client}-${var.project}-${var.environment}"

  # Physical resource names adhering strictly to <= 28 characters
  bucket_name          = "${local.name_prefix}-s3-focus-conf"
  dlq_name             = "${local.name_prefix}-sqs-focus-dlq"
  lambda_function_name = "${local.name_prefix}-fn-focus-conf"
  iam_role_name        = "${local.name_prefix}-role-focus-fn"
  iam_policy_name      = "${local.name_prefix}-pol-focus-fn"

  # AWS Context
  account_id = data.aws_caller_identity.current.account_id
  aws_region = data.aws_region.current.name
  partition  = data.aws_partition.current.partition

  # Effective IAM Role ARN
  effective_role_arn = var.create_iam_role ? aws_iam_role.this[0].arn : var.custom_iam_role_arn

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

