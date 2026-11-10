# Intrinsic session data for generating zero-wildcard IAM policies
# Per PC-IAC-011, external infrastructure data sources reside in root.
# Only intrinsic AWS partition/account/region metadata is resolved here.
data "aws_caller_identity" "current" {
  provider = aws.project
}

data "aws_region" "current" {
  provider = aws.project
}
