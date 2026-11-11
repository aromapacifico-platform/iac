provider "aws" {
  alias  = "principal"
  region = "us-east-1"
  default_tags { tags = local.default_tags }
}
