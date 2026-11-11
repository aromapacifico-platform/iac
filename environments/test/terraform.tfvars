# Non-sensitive values only. Secrets never go in tfvars.
# Explicit endpoint_access grants remain pending PR #8's environment tfvars.
# See docs/iac/ci-plan-inputs.md for final plan prerequisites.
environment        = "test"
aws_region         = "us-east-1"
availability_zones = ["us-east-1a", "us-east-1b"]
vpc_cidr           = "10.60.0.0/16"

# Test has no route to real collection centers.
collection_center_cidrs = {}

endpoint_access = {
  s3 = {
    principal_arns = ["arn:aws:iam::273577169715:role/aromapacifico-ci-test"]
    actions        = ["s3:GetObject", "s3:PutObject", "s3:ListBucket"]
    resource_arns = [
      "arn:aws:s3:::aromapacifico-tfstate-test",
      "arn:aws:s3:::aromapacifico-tfstate-test/*"
    ]
  }
  dynamodb = {
    principal_arns = ["arn:aws:iam::273577169715:role/aromapacifico-ci-test"]
    actions        = ["dynamodb:GetItem", "dynamodb:PutItem", "dynamodb:Query"]
    resource_arns  = ["arn:aws:dynamodb:us-east-1:273577169715:table/aromapacifico-test-telemetry"]
  }
}
