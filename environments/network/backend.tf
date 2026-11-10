# Dedicated central Network state. Supply actual bucket/key/KMS settings at init.
terraform {
  backend "s3" {}
}
