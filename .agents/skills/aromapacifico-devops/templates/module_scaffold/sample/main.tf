module "sample" {
  source = "../"

  providers = {
    aws.project = aws.principal
  }

  client      = local.client
  project     = local.project
  environment = local.environment
}
