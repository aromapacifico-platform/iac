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

security_network = {
  authorized_private_cidrs = ["10.50.0.0/16"]
  visitor_cidr             = "10.41.5.0/24"
  log_authorized_cidr      = "10.41.3.0/24"
  drone_backup_cidrs       = ["10.41.20.0/24"]
  admin_cidr               = "10.41.1.0/24"
  dns_cidr                 = "10.41.10.0/24"
  app_cidr                 = "10.50.10.0/24"
}

endpoint_access = {
  s3 = {
    principal_arns = ["arn:aws:iam::273577169715:role/aromapacifico-ci-dev"]
    actions        = ["s3:GetObject", "s3:PutObject", "s3:ListBucket"]
    resource_arns = [
      "arn:aws:s3:::aromapacifico-tfstate-dev",
      "arn:aws:s3:::aromapacifico-tfstate-dev/*"
    ]
  }
  dynamodb = {
    principal_arns = ["arn:aws:iam::273577169715:role/aromapacifico-ci-dev"]
    actions        = ["dynamodb:GetItem", "dynamodb:PutItem", "dynamodb:Query"]
    resource_arns  = ["arn:aws:dynamodb:us-east-1:273577169715:table/aromapacifico-dev-telemetry"]
  }
}


# CSR público de ejemplo para que el plan de dev corra en el pipeline. Su llave
# privada se descartó al generarlo; el nodo real genera su propio CSR en el
# elemento seguro y lo reemplaza aquí. El certificado queda inactivo.
farm_certificate_csr = <<-EOT
-----BEGIN CERTIFICATE REQUEST-----
MIHnMIGNAgEAMCsxETAPBgNVBAMMCENBVS1GMDAxMRYwFAYDVQQKDA1Bcm9tYVBh
Y2lmaWNvMFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAEgnTQQ7/iHmB2mwuYgXLU
tNKrN4NW8PT8N9fBNNNMFSDP/OngXvYfoiQITpUpNBYUbtiAbZ40IaDVY58evs2q
IqAAMAoGCCqGSM49BAMCA0kAMEYCIQDbtYBD+29KvtUpgca+mPiqhQRK2/5POmZA
ElhnCu5+VAIhAL891LU2NF+/Pymx7yRRMwnLp+XUWe8nTs10Uhiz5Gp/
-----END CERTIFICATE REQUEST-----
EOT
