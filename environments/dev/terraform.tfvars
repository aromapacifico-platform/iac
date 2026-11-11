# Non-sensitive values only. Secrets never go in tfvars.
environment        = "dev"
aws_region         = "us-east-1"
availability_zones = ["us-east-1a", "us-east-1b"]
vpc_cidr           = "10.50.0.0/16"

# Dev has no route to real collection centers.
collection_center_cidrs = {}

# Security names intentionally retain the existing module contract.
client                  = "fnc"
project                 = "aromapacifico"
farm_id                 = "CAU-F001"
farm_certificate_active = false

# Provide farm_certificate_csr through an untracked *.local.tfvars file.
security_network = {
  authorized_private_cidrs = ["10.50.0.0/16"]
  visitor_cidr             = "10.41.5.0/24"
  log_authorized_cidr      = "10.41.3.0/24"
  drone_backup_cidrs       = ["10.41.20.0/24"]
  admin_cidr               = "10.41.1.0/24"
  dns_cidr                 = "10.41.10.0/24"
  app_cidr                 = "10.50.10.0/24"
}
