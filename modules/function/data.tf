# ==============================================================================
# Internal Data Sources (PC-IAC-011)
# ==============================================================================

data "aws_caller_identity" "current" {
  provider = aws.project
}

data "aws_region" "current" {
  provider = aws.project
}

data "aws_partition" "current" {
  provider = aws.project
}

# Archive packaging for the Lambda deployment bundle
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/src"
  output_path = "${path.module}/dist/focus_confirmation.zip"
}
