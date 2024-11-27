# ACM
output "acm_certificate_arn" {
  description = "The ARN of the ACM Certificate"
  value       = aws_acm_certificate.cert.arn
}

output "acm_certificate_id" {
  description = "The ARN of the ACM Certificate"
  value       = aws_acm_certificate.cert.id
}


# Cloudfront
output "cf_distribution_arn" {
  description = "The ARN of the CloudFront distribution"
  value       = aws_cloudfront_distribution.cf_distribution.arn
}

output "cf_distribution_id" {
  description = "The identifier of the CloudFront distribution"
  value       = aws_cloudfront_distribution.cf_distribution.id
}

output "cf_request_function_arn" {
  description = "The ARN of the CloudFront Function in charge of adding support for directory index documents."
  value       = aws_cloudfront_function.cf_function_request.arn
}

output "cf_response_function_arn" {
  description = "The ARN of the CloudFront Function in charge of supporting x-amz-website-redirect-location on objects."
  value       = aws_cloudfront_function.cf_function_response.arn
}

# S3
output "s3_bucket_arn" {
  description = "The ARN of the S3 Bucket"
  value       = aws_s3_bucket.bucket.arn
}

output "s3_bucket_id" {
  description = "The ID of the S3 Bucket"
  value       = aws_s3_bucket.bucket.id
}
