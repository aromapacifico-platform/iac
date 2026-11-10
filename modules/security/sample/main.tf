# Sample mock VPC to provide an isolated test fixture for the security module
resource "aws_vpc" "sample" {
  provider   = aws.principal
  cidr_block = "10.50.0.0/16"

  tags = {
    Name = "${local.name_prefix}-sample-vpc"
  }
}

resource "aws_subnet" "sample_private" {
  provider          = aws.principal
  vpc_id            = aws_vpc.sample.id
  cidr_block        = "10.50.1.0/24"
  availability_zone = "${var.aws_region}a"

  tags = {
    Name = "${local.name_prefix}-sample-private-subnet"
  }
}

resource "aws_subnet" "sample_public" {
  provider          = aws.principal
  vpc_id            = aws_vpc.sample.id
  cidr_block        = "10.50.50.0/24"
  availability_zone = "${var.aws_region}a"

  tags = {
    Name = "${local.name_prefix}-sample-public-subnet"
  }
}

# Module invocation strictly complying with PC-IAC-013, PC-IAC-021, PC-IAC-026
module "security" {
  # Section A: source and version
  source = "../"

  # Section B: providers mapping
  providers = {
    aws.project = aws.principal
  }

  # Section C: governance variables
  client      = local.client
  project     = local.project
  environment = local.environment

  # Section D: transversal infrastructure dependencies
  vpc_id             = aws_vpc.sample.id
  private_subnet_ids = [aws_subnet.sample_private.id]
  public_subnet_ids  = [aws_subnet.sample_public.id]

  # Section E: resource specific configurations
  authorized_private_cidrs    = ["10.50.0.0/16"]
  visitor_cidr                = "10.41.5.0/24"
  log_authorized_cidr         = "10.41.3.0/24"
  drone_backup_cidrs          = ["10.41.20.0/24"]
  admin_cidr                  = "10.41.1.0/24"
  dns_cidr                    = "10.41.10.0/24"
  app_cidr                    = "10.50.10.0/24"
  kms_deletion_window_in_days = 30

  additional_tags = local.sample_tags
}

