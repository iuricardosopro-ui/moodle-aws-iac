# Route53 is opt-in: it only makes sense once you actually own a domain
# and have a hosted zone for it. A portfolio project has neither by
# default, so this module does nothing unless both domain_name and
# route53_zone_id are supplied — the site is reached via the ALB's or
# CloudFront's own AWS-provided DNS name until then.
resource "aws_route53_record" "root" {
  count = var.domain_name != "" && var.route53_zone_id != "" ? 1 : 0

  zone_id = var.route53_zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = var.cloudfront_domain_name
    zone_id                = var.cloudfront_hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "www" {
  count = var.domain_name != "" && var.route53_zone_id != "" && var.create_www_record ? 1 : 0

  zone_id = var.route53_zone_id
  name    = "www.${var.domain_name}"
  type    = "CNAME"
  ttl     = 300
  records = [var.domain_name]
}
