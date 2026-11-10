# Provider declarations and alias definitions (PC-IAC-005)
# In accordance with PC-IAC-005, modules consume providers via configuration_aliases.
terraform {
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      version               = "~> 5.0"
      configuration_aliases = [aws.project]
    }
  }
}
