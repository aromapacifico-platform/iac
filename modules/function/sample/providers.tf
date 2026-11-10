# Provider configuration for sample fixture (PC-IAC-004, PC-IAC-005, PC-IAC-006)
terraform {
  required_version = ">= 1.10.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.4"
    }
  }
}

provider "aws" {
  alias  = "principal"
  region = var.aws_region

  default_tags {
    tags = {
      FincaID     = "GLOBAL"
      DronID      = "NO-APLICA"
      AcopioID    = "MULTICENTRO"
      ViajeID     = "NO-APLICA"
      Ambiente    = var.environment
      Propietario = "devops-fnc"
      Proyecto    = "AromaPacifico"
    }
  }
}
