provider "aws" {
  region              = var.aws_region
  allowed_account_ids = [var.network_account_id]
  assume_role {
    role_arn = var.network_role_arn
  }
  default_tags {
    tags = local.default_tags
  }
}

provider "aws" {
  alias               = "principal"
  region              = var.aws_region
  allowed_account_ids = [var.network_account_id]
  assume_role {
    role_arn = var.network_role_arn
  }
  default_tags {
    tags = local.default_tags
  }
}
