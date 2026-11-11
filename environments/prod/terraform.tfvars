# Non-sensitive values only. Secrets never go in tfvars.
# CI supplies endpoint_access from ENDPOINT_ACCESS_PROD (JSON), with no default.
# See docs/iac/ci-plan-inputs.md for the exact external input contract.
environment        = "prod"
aws_region         = "us-east-1"
availability_zones = ["us-east-1a", "us-east-1b"]
vpc_cidr           = "10.70.0.0/16"

collection_center_cidrs = {
  ACOPIO-CAUCA  = "10.41.0.0/16"
  ACOPIO-HUILA  = "10.42.0.0/16"
  ACOPIO-TOLIMA = "10.43.0.0/16"
}
