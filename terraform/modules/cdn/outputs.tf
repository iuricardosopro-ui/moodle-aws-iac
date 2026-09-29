output "domain_name" {
  value = aws_cloudfront_distribution.this.domain_name
}

output "hosted_zone_id" {
  description = "CloudFront's fixed hosted zone ID, used by Route53 alias records."
  value       = aws_cloudfront_distribution.this.hosted_zone_id
}
