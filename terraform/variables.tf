variable "aws_region" {
  type        = string
  description = "The AWS region to put the bucket into"
  default     = "eu-central-1"
}

variable "aws_profile" {
  type        = string
  description = "AWS Profile"
}

variable "cloudflare_api_token" {
  type        = string
  description = "The API Token for operations"
}

variable "site_domain" {
  type        = string
  description = "The domain name to use for the static site"
}