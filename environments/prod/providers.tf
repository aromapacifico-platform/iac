# Credentials come from the caller: an IAM Identity Center session locally, or
# the OIDC role in the pipeline. Nothing here holds keys.
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = local.default_tags
  }
}
