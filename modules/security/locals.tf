locals {
  name_prefix = "${var.client}-${var.project}-${var.environment}"

  # Standard tags per PC-IAC-004
  common_tags = merge(
    var.additional_tags,
    {
      Component = "Security"
      ManagedBy = "Terraform"
    }
  )

  account_id = data.aws_caller_identity.current.account_id
  aws_region = data.aws_region.current.name

  # Customer Managed Keys definitions per PC-IAC-010
  kms_keys = {
    data = {
      description = "Customer Managed Key for agricultural telemetry and sack master ledger"
      alias       = "alias/${local.name_prefix}-kms-data"
    }
    objects = {
      description = "Customer Managed Key for drone flight binaries, images and inference objects"
      alias       = "alias/${local.name_prefix}-kms-objects"
    }
    logs = {
      description = "Customer Managed Key for CloudWatch audit traces, state locking and flow logs"
      alias       = "alias/${local.name_prefix}-kms-logs"
    }
  }
}
