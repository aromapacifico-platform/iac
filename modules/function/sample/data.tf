# ==============================================================================
# Sample Fixture Data Sources (PC-IAC-011)
# ==============================================================================

data "aws_caller_identity" "current" {
  provider = aws.principal
}

data "aws_region" "current" {
  provider = aws.principal
}
