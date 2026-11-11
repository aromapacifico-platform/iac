# Non-sensitive values only. Secrets never go in tfvars.
environment        = "dev"
aws_region         = "us-east-1"
availability_zones = ["us-east-1a", "us-east-1b"]
vpc_cidr           = "10.50.0.0/16"

# Dev has no route to real collection centers.
collection_center_cidrs = {}

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
