locals {
  s3_origin_id     = var.cf_website_origin_id != "" ? var.cf_website_origin_id : "S3Website-${local.resolved_bucket_name}"

  resolved_cf_request_function_name  = var.cf_request_function_name != "" ? var.cf_request_function_name : "${local.default_resource_prefix}-cf-reqfunc"
  resolved_cf_response_function_name = var.cf_response_function_name != "" ? var.cf_response_function_name : "${local.default_resource_prefix}-cf-resfunc"

  resolved_cf_oac_name = var.cf_oac_name != "" ? var.cf_oac_name : "${local.default_resource_prefix}-cf-oac"
}

resource "aws_cloudfront_distribution" "cf_distribution" {
  enabled         = var.is_cloudfront_enabled
  is_ipv6_enabled = var.is_ipv6_enabled

  comment = "${local.main_domain} (Terraform Managed)"
  tags    = var.tags

  price_class = var.cf_price_class

  web_acl_id = length(var.cf_waf_acl_id) > 0 ? var.cf_waf_acl_id : null

  aliases = var.domains

  default_root_object = var.index_document

  # AWS S3 returns a 403 if an object doesn't exist
  custom_error_response {
    error_code         = 403
    response_code      = 404
    response_page_path = "/${var.error_document}"
  }

  custom_error_response {
    error_code         = 404
    response_code      = 404
    response_page_path = "/${var.error_document}"
  }

  default_cache_behavior {
    allowed_methods = [
      "GET",
      "HEAD",
      "OPTIONS",
    ]
    cached_methods = [
      "GET",
      "HEAD",
      "OPTIONS",
    ]

    compress = true

    target_origin_id       = local.s3_origin_id
    viewer_protocol_policy = "redirect-to-https"

    cache_policy_id            = var.cf_website_cache_policy_id
    origin_request_policy_id   = length(var.cf_website_origin_request_policy_id) > 0 ? var.cf_website_origin_request_policy_id : null
    response_headers_policy_id = length(var.cf_website_response_headers_policy_id) > 0 ? var.cf_website_response_headers_policy_id : null

    function_association {
      event_type   = "viewer-request"
      function_arn = aws_cloudfront_function.cf_function_request.arn
    }

    function_association {
      event_type   = "viewer-response"
      function_arn = aws_cloudfront_function.cf_function_response.arn
    }
  }

  origin {
    origin_id   = local.s3_origin_id
    domain_name = aws_s3_bucket.bucket.bucket_regional_domain_name

    origin_access_control_id = aws_cloudfront_origin_access_control.cf_oac.id
  }

  dynamic "origin" {
    for_each = toset(var.cf_custom_origins)
    content {
      origin_id   = origin.value.origin_id
      origin_path = length(origin.value.origin_path) > 0 ? origin.value.origin_path : null

      domain_name = origin.value.domain_name

      origin_access_control_id = length(origin.value.origin_access_control_id) > 0 ? (origin.value.origin_access_control_id == "self" ? aws_cloudfront_origin_access_control.cf_oac.id : origin.value.origin_access_control_id) : null

      dynamic "custom_header" {
        for_each = toset(origin.value.custom_headers)
        content {
          name  = custom_header.value.name
          value = custom_header.value.value
        }
      }

      dynamic "custom_origin_config" {
        for_each = origin.value.custom_origin_config != null ? ["custom_origin_config"] : []

        content {
          http_port  = origin.value.custom_origin_config.http_port
          https_port = origin.value.custom_origin_config.https_port

          origin_protocol_policy = origin.value.custom_origin_config.origin_protocol_policy
          origin_ssl_protocols   = origin.value.custom_origin_config.origin_ssl_protocols

          origin_read_timeout = origin.value.custom_origin_config.origin_read_timeout
        }
      }
    }
  }

  dynamic "ordered_cache_behavior" {
    for_each = toset(var.cf_custom_behaviors)
    content {
      path_pattern = ordered_cache_behavior.value.path_pattern

      allowed_methods = ordered_cache_behavior.value.allowed_methods
      cached_methods  = ordered_cache_behavior.value.cached_methods

      compress = ordered_cache_behavior.value.compress

      target_origin_id       = ordered_cache_behavior.value.target_origin_id
      viewer_protocol_policy = ordered_cache_behavior.value.viewer_protocol_policy

      cache_policy_id            = ordered_cache_behavior.value.cache_policy_id
      origin_request_policy_id   = length(ordered_cache_behavior.value.origin_request_policy_id) > 0 ? ordered_cache_behavior.value.origin_request_policy_id : null
      response_headers_policy_id = length(ordered_cache_behavior.value.response_headers_policy_id) > 0 ? ordered_cache_behavior.value.response_headers_policy_id : null

      dynamic "function_association" {
        for_each = ordered_cache_behavior.value.apply_s3_functions == true ? [{
          event_type   = "viewer-request"
          function_arn = aws_cloudfront_function.cf_function_request.arn
          }, {
          event_type   = "viewer-response"
          function_arn = aws_cloudfront_function.cf_function_response.arn
        }] : ordered_cache_behavior.value.function_association

        content {
          event_type   = function_association.value.event_type
          function_arn = function_association.value.function_arn
        }
      }
    }
  }

  dynamic "logging_config" {
    for_each = var.cf_logging_config.bucket != "" ? ["logging_config"] : []
    content {
      bucket = "${var.cf_logging_config.bucket}.s3.amazonaws.com"
      prefix = var.cf_logging_config.prefix != "" ? var.cf_logging_config.prefix : null

      include_cookies = var.cf_logging_config.include_cookies
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate_validation.cert_validation.certificate_arn
    minimum_protocol_version = var.cf_minimum_protocol_version
    ssl_support_method       = "sni-only"
  }
}

resource "aws_cloudfront_origin_access_control" "cf_oac" {
  name        = local.resolved_cf_oac_name
  description = "${local.main_domain} (Terraform Managed)"

  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_function" "cf_function_request" {
  name    = local.resolved_cf_request_function_name
  comment = "${local.main_domain} Viewer Request Function (Terraform Managed)"

  runtime = "cloudfront-js-1.0"
  publish = true

  code = templatefile("${path.module}/files/cf-func-request.js.tftpl", {
    index_document = jsonencode(var.index_document)
  })
}

resource "aws_cloudfront_function" "cf_function_response" {
  name    = local.resolved_cf_response_function_name
  comment = "${local.main_domain} Viewer Response Function (Terraform Managed)"

  runtime = "cloudfront-js-1.0"
  publish = true

  code = file("${path.module}/files/cf-func-response.js")
}
