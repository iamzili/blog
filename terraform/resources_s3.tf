locals {
  resolved_bucket_name = var.bucket_name == "" ? local.main_domain : var.bucket_name
}

# Bucket
resource "aws_s3_bucket" "bucket" {
  bucket = local.resolved_bucket_name

  force_destroy = var.bucket_force_destroy

  tags = var.tags
}

resource "aws_s3_bucket_ownership_controls" "bucket_ownership" {
  bucket = aws_s3_bucket.bucket.id

  rule {
    object_ownership = var.bucket_object_ownership
  }
}

resource "aws_s3_bucket_acl" "bucket_acl" {
  count = var.bucket_object_ownership == "BucketOwnerEnforced" ? 0 : 1

  bucket = aws_s3_bucket.bucket.id
  acl    = "private"

  depends_on = [aws_s3_bucket_ownership_controls.bucket_ownership]
}

resource "aws_s3_bucket_public_access_block" "bucket_public_access_block" {
  bucket = aws_s3_bucket.bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "bucket_versioning" {
  bucket = aws_s3_bucket.bucket.id

  versioning_configuration {
    status = "Suspended"
  }
}

# Bucket Access Policy
data "aws_iam_policy_document" "bucket_policy" {
  statement {
    sid = "CloudFrontOACRead"

    actions = [
      "s3:GetObject"
    ]

    principals {
      identifiers = ["cloudfront.amazonaws.com"]
      type        = "Service"
    }

    resources = [
      "${aws_s3_bucket.bucket.arn}/*",
    ]

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.cf_distribution.arn]
    }
  }
  statement {
    sid    = "DenyInsecureTraffic"
    effect = "Deny"

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions = ["s3:*"]

    resources = [
      "${aws_s3_bucket.bucket.arn}",
      "${aws_s3_bucket.bucket.arn}/*"
    ]

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }

  override_policy_documents = var.bucket_override_policy_documents
}

resource "aws_s3_bucket_policy" "bucket_policy" {
  bucket = aws_s3_bucket.bucket.id
  policy = data.aws_iam_policy_document.bucket_policy.json

  depends_on = [
    aws_s3_bucket_public_access_block.bucket_public_access_block,
    aws_cloudfront_distribution.cf_distribution,
  ]
}
