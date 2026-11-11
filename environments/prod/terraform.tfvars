# Non-sensitive values only. Secrets never go in tfvars.
# Explicit endpoint_access grants remain pending PR #8's environment tfvars.
# See docs/iac/ci-plan-inputs.md for final plan prerequisites.
environment        = "prod"
aws_region         = "us-east-1"
availability_zones = ["us-east-1a", "us-east-1b"]
vpc_cidr           = "10.70.0.0/16"

collection_center_cidrs = {
  ACOPIO-CAUCA  = "10.41.0.0/16"
  ACOPIO-HUILA  = "10.42.0.0/16"
  ACOPIO-TOLIMA = "10.43.0.0/16"
}
