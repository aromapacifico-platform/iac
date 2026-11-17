# Non-sensitive values only. Secrets never go in tfvars.
environment        = "prod"
aws_region         = "us-east-1"
availability_zones = ["us-east-1a", "us-east-1b"]
vpc_cidr           = "10.70.0.0/16"

collection_center_cidrs = {
  ACOPIO-CAUCA  = "10.41.0.0/16"
  ACOPIO-HUILA  = "10.42.0.0/16"
  ACOPIO-TOLIMA = "10.43.0.0/16"
}

# Security names intentionally retain the existing module contract.
client                  = "fnc"
project                 = "aromapacifico"
farm_id                 = "CAU-F001"
farm_certificate_active = false

security_network = {
  authorized_private_cidrs = ["10.70.0.0/16"]
  visitor_cidr             = "10.41.5.0/24"
  log_authorized_cidr      = "10.41.3.0/24"
  drone_backup_cidrs       = ["10.41.20.0/24"]
  admin_cidr               = "10.41.1.0/24"
  dns_cidr                 = "10.41.10.0/24"
  app_cidr                 = "10.70.10.0/24"
}

endpoint_access = {
  s3 = {
    principal_arns = ["arn:aws:iam::273577169715:role/aromapacifico-ci-prod"]
    actions        = ["s3:GetObject", "s3:PutObject", "s3:ListBucket"]
    resource_arns = [
      "arn:aws:s3:::aromapacifico-tfstate-prod",
      "arn:aws:s3:::aromapacifico-tfstate-prod/*"
    ]
  }
  dynamodb = {
    principal_arns = ["arn:aws:iam::273577169715:role/aromapacifico-ci-prod"]
    actions        = ["dynamodb:GetItem", "dynamodb:PutItem", "dynamodb:Query"]
    resource_arns  = ["arn:aws:dynamodb:us-east-1:273577169715:table/aromapacifico-prod-telemetry"]
  }
}

# Public example CSR so the prod plan runs in the pipeline without secrets.
farm_certificate_csr = <<-EOT
-----BEGIN CERTIFICATE REQUEST-----
MIHnMIGNAgEAMCsxETAPBgNVBAMMCENBVS1GMDAxMRYwFAYDVQQKDA1Bcm9tYVBh
Y2lmaWNvMFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAEgnTQQ7/iHmB2mwuYgXLU
tNKrN4NW8PT8N9fBNNNMFSDP/OngXvYfoiQITpUpNBYUbtiAbZ40IaDVY58evs2q
IqAAMAoGCCqGSM49BAMCA0kAMEYCIQDbtYBD+29KvtUpgca+mPiqhQRK2/5POmZA
ElhnCu5+VAIhAL891LU2NF+/Pymx7yRRMwnLp+XUWe8nTs10Uhiz5Gp/
-----END CERTIFICATE REQUEST-----
EOT
