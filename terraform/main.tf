### Providers
terraform {
  required_version = ">= 1.7"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.34"
    }
  }
}

locals {
  default_resource_prefix = replace(local.main_domain, "/[^a-zA-Z0-9_-]/", "_")
}
