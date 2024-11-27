variable "domains" {
  description = "List of domains for which the CloudFront Distribution will be serving files."
  type        = list(string)

  validation {
    condition     = length(var.domains) >= 1
    error_message = "You must specify at least one domain name in the list."
  }

  validation {
    condition     = length(var.domains) == length(toset(var.domains))
    error_message = "Values in the list must be unique."
  }
}

variable "zone_ids" {
  description = "List of Route53 zone IDs for the domains specified in var.domains"
  type        = list(string)
}

# Bucket Configuration
variable "bucket_name" {
  description = "S3 bucket name used to deploy the website resources on. If left empty, defaults to using the first domain as name."
  type        = string
  default     = ""
}

variable "bucket_force_destroy" {
  description = "Allow Terraform to destroy the bucket even if there are objects within."
  type        = bool
  default     = false
}

variable "bucket_object_ownership" {
  description = "S3 bucket ownership scheme."
  type        = string
  default     = "BucketOwnerEnforced"
}

variable "bucket_override_policy_documents" {
  description = "S3 bucket override policy documents (in JSON)."
  type        = list(string)
  default     = []
}

variable "index_document" {
  description = "Filename of the index document to be used in the bucket."
  type        = string
  default     = "index.html"

  validation {
    condition     = length(var.index_document) > 0
    error_message = "Value cannot be empty."
  }
}

variable "error_document" {
  description = "Filename of the error document to be used in the bucket."
  type        = string
  default     = "error.html"

  validation {
    condition     = length(var.error_document) > 0
    error_message = "Value cannot be empty."
  }
}

# CloudFont Parameters
variable "is_cloudfront_enabled" {
  description = "Allows disabling the CloudFront distribution. Note that records will be deleted if CF is disabled."
  type        = bool
  default     = true
}

variable "is_ipv6_enabled" {
  description = "Toggles if IPv6 is enabled on the CloudFront distribution. If enabled, it will automatically create relevant AAAA records."
  type        = bool
  default     = true
}

variable "cf_logging_config" {
  description = "Provides logging configuration for the CloudFront distribution"
  type = object({
    bucket          = optional(string)
    include_cookies = optional(bool, false)
    prefix          = optional(string)
  })
  default = {}
}

variable "cf_price_class" {
  description = "CloudFront Price Class"
  type        = string
  default     = "PriceClass_All"
}

variable "cf_minimum_protocol_version" {
  description = "CloudFront SSL/TLS Minimum Protocol Version"
  type        = string
  default     = "TLSv1.2_2021"
}

variable "cf_website_origin_id" {
  description = "CloudFront origin id that will be used for the origin pointing to the API gateway. Will be automatically generated if empty."
  type        = string
  default     = ""
}

variable "cf_website_cache_policy_id" {
  description = "Cache Policy Id to apply to the default (S3 bucket) cache behavior of the CloudFront distribution. Defaults to 'Managed-CachingOptimized'"
  type        = string
  default     = "658327ea-f89d-4fab-a63d-7e88639e58f6"
}

variable "cf_website_origin_request_policy_id" {
  description = "Origin Request Policy Id to apply to the default (S3 bucket) cache behavior of the CloudFront distribution. Defaults to 'Managed-CORS-S3Origin'. Leave empty for none."
  type        = string
  default     = "88a5eaf4-2fd4-4709-b370-b4c650ea3fcf"
}

variable "cf_website_response_headers_policy_id" {
  description = "Response Headers Policy Id to apply to the default (S3 bucket) cache behavior of the CloudFront distribution. Defaults to none. Leave empty for none."
  type        = string
  default     = ""
}

variable "cf_request_function_name" {
  description = "Name of the CloudFront Function in charge of adding support for directory index documents. If left empty, a value will be derived from the first domain name."
  type        = string
  default     = ""
}

variable "cf_response_function_name" {
  description = "Name of the CloudFront Function in charge of supporting x-amz-website-redirect-location on objects. If left empty, a value will be derived from the first domain name."
  type        = string
  default     = ""
}

variable "cf_oac_name" {
  description = "Name of the CloudFront Origin Access Control. If left empty, a value will be derived from the first domain name."
  type        = string
  default     = ""
}

variable "cf_custom_origins" {
  description = "List of additional custom origins for which to selectively route traffic to."
  type = list(object({
    origin_id   = string
    origin_path = optional(string, "")
    domain_name = string
    custom_headers = optional(list(object({
      name  = string
      value = string
    })), [])
    custom_origin_config = optional(object({
      http_port              = number
      https_port             = number
      origin_protocol_policy = string
      origin_ssl_protocols   = list(string)
      origin_read_timeout    = number
    }))
    origin_access_control_id = optional(string, "")
  }))
  default = []
}

variable "cf_custom_behaviors" {
  description = "List of additional CloudFront behaviors."
  type = list(object({
    target_origin_id           = string
    path_pattern               = string
    allowed_methods            = list(string)
    cached_methods             = list(string)
    compress                   = optional(bool, false)
    viewer_protocol_policy     = string
    cache_policy_id            = optional(string, "")
    origin_request_policy_id   = optional(string, "")
    response_headers_policy_id = optional(string, "")
    apply_s3_functions         = optional(bool, false)
    function_association = optional(list(object({
      event_type   = string
      function_arn = string
    })), [])
  }))
  default = []
}

variable "cf_waf_acl_id" {
  description = "Unique identifier that specifies the AWS WAF web ACL, if any, to associate with this distribution."
  type        = string
  default     = ""
}

# General Variables
variable "tags" {
  description = "AWS tags to apply to every resource created by this module"
  type        = map(string)
  default     = {}
}
