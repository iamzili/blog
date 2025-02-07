terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.86.0"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "5.0.0"
    }
  }
}