output "bucket_name" {
  description = "S3 bucket hosting the SPA assets."
  value       = aws_s3_bucket.this.id
}

output "bucket_arn" {
  description = "S3 bucket ARN."
  value       = aws_s3_bucket.this.arn
}

output "bucket_regional_domain_name" {
  description = "S3 bucket regional domain name used as the CloudFront origin."
  value       = aws_s3_bucket.this.bucket_regional_domain_name
}

output "distribution_id" {
  description = "CloudFront distribution ID. Use this for cache invalidations after deploys."
  value       = aws_cloudfront_distribution.this.id
}

output "distribution_arn" {
  description = "CloudFront distribution ARN."
  value       = aws_cloudfront_distribution.this.arn
}

output "distribution_domain_name" {
  description = "CloudFront distribution domain name (d1234.cloudfront.net)."
  value       = aws_cloudfront_distribution.this.domain_name
}

output "distribution_hosted_zone_id" {
  description = "Route 53 hosted zone ID for the CloudFront distribution. Use for alias records."
  value       = aws_cloudfront_distribution.this.hosted_zone_id
}

output "origin_access_control_id" {
  description = "CloudFront Origin Access Control ID."
  value       = aws_cloudfront_origin_access_control.this.id
}

output "cache_policy_id" {
  description = "Custom CloudFront cache policy ID attached to the default behavior."
  value       = aws_cloudfront_cache_policy.this.id
}
