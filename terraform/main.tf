locals {
  tags = {
    terraform   = "true"
    environment = var.environment
    live        = var.environment == "prod" ? "yes" : "no"
  }
}

terraform {
  backend "s3" {}
}
