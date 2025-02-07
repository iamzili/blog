provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile
}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}

resource "aws_s3_bucket" "site" {
  bucket        = var.site_domain
  force_destroy = true
}

resource "aws_s3_bucket_public_access_block" "site" {
  bucket = aws_s3_bucket.site.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_website_configuration" "site" {
  bucket = aws_s3_bucket.site.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}

resource "aws_s3_bucket_ownership_controls" "site" {
  bucket = aws_s3_bucket.site.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "site" {
  bucket = aws_s3_bucket.site.id

  acl = "public-read"
  depends_on = [
    aws_s3_bucket_ownership_controls.site,
    aws_s3_bucket_public_access_block.site
  ]
}

resource "aws_s3_bucket_policy" "site" {
  bucket = aws_s3_bucket.site.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource = [
          aws_s3_bucket.site.arn,
          "${aws_s3_bucket.site.arn}/*",
        ]
      },
    ]
  })

  depends_on = [
    aws_s3_bucket_public_access_block.site
  ]
}

//The cloudflare_zones.domain data source retrieves your Cloudflare zone ID
data "cloudflare_zones" "domain" {
  name = var.site_domain
}

resource "cloudflare_dns_record" "site_cname" {
  zone_id = data.cloudflare_zones.domain.result[0].id
  name    = var.site_domain
  content = aws_s3_bucket_website_configuration.site.website_endpoint
  type    = "CNAME"

  ttl     = 1
  proxied = true
}

resource "cloudflare_dns_record" "www" {
  zone_id = data.cloudflare_zones.domain.result[0].id
  name    = "www"
  content = var.site_domain
  type    = "CNAME"

  ttl     = 1
  proxied = true
}

resource "cloudflare_page_rule" "forward_www_to_naked_domain" {
  zone_id = data.cloudflare_zones.domain.result[0].id
  target  = "www.${var.site_domain}/*"
  priority = 2
  status = "active"
  actions = {
    forwarding_url = {
      status_code = 301
      url         = "https://${var.site_domain}/$1"
    }
  }
}

// Redirect all requests with scheme “http” to “https”. This applies to all http requests to the zone.
// The following changes the settings within SSL/TLS --> Edge Certificates
resource "cloudflare_zone_setting" "setting" {
    zone_id = data.cloudflare_zones.domain.result[0].id
    setting_id = "always_use_https"
    value = "on"
}