output "frontend_bucket" {
  value = aws_s3_bucket.frontend_bucket
}

output "cloudfront_domain_name" {
  value = aws_cloudfront_distribution.s3_distribution.domain_name
}