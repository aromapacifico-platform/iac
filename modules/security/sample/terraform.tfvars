aws_region  = "us-east-1"
environment = "dev"

vpc_id             = "vpc-0123456789abcdef0"
private_subnet_ids = ["subnet-0123456789abcdef0"]
public_subnet_ids  = ["subnet-0123456789abcdef1"]

authorized_private_cidrs    = ["10.50.0.0/16"]
visitor_cidr                = "10.41.5.0/24"
log_authorized_cidr         = "10.41.3.0/24"
drone_backup_cidrs          = ["10.41.20.0/24"]
admin_cidr                  = "10.41.1.0/24"
dns_cidr                    = "10.41.10.0/24"
app_cidr                    = "10.50.10.0/24"
kms_deletion_window_in_days = 30

additional_tags = {
  Sample = "True"
}
