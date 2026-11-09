# Non-sensitive values only. Secrets never go in tfvars.
environment        = "dev"
aws_region         = "us-east-1"
availability_zones = ["us-east-1a", "us-east-1b"]
vpc_cidr           = "10.50.0.0/16"

# Dev has no route to real collection centers.
collection_center_cidrs = {}
