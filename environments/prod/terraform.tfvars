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
