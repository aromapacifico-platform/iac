# Non-sensitive values only. Secrets never go in tfvars.
# Explicit endpoint_access grants remain pending PR #8's environment tfvars.
# See docs/iac/ci-plan-inputs.md for final plan prerequisites.
environment        = "test"
aws_region         = "us-east-1"
availability_zones = ["us-east-1a", "us-east-1b"]
vpc_cidr           = "10.60.0.0/16"

# Test has no route to real collection centers.
collection_center_cidrs = {}
