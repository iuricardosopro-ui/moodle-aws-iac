# CloudFront in front of the ALB: caches static assets closer to users
# and terminates TLS at the edge. Off by default (see enable_cdn in the
# environment) because it only pays for itself once there is real
# traffic outside a single AWS region — a dev box nobody else hits does
# not need it.
resource "aws_cloudfront_distribution" "this" {
  enabled     = true
  comment     = "${var.project_name} - Moodle"
  price_class = var.price_class

  origin {
    domain_name = var.alb_dns_name
    origin_id   = "alb-origin"

    custom_origin_config {
      http_port              = 80
      https_port              = 443
      origin_protocol_policy  = "http-only" # the ALB has no HTTPS listener in this environment (see README)
      origin_ssl_protocols    = ["TLSv1.2"]
    }
  }

  default_cache_behavior {
    target_origin_id       = "alb-origin"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods         = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
    cached_methods           = ["GET", "HEAD"]

    # Moodle is a dynamic app — session cookies and CSRF tokens are on
    # nearly every request. Caching is intentionally disabled here so
    # login and course pages are never served stale; a separate cache
    # behavior for static theme assets (CSS/JS/images) with a long TTL
    # is a reasonable follow-up once real traffic patterns are known.
    forwarded_values {
      query_string = true
      headers      = ["*"]

      cookies {
        forward = "all"
      }
    }

    min_ttl     = 0
    default_ttl = 0
    max_ttl     = 0
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = var.acm_certificate_arn == "" ? true : null
    acm_certificate_arn            = var.acm_certificate_arn == "" ? null : var.acm_certificate_arn
    ssl_support_method              = var.acm_certificate_arn == "" ? null : "sni-only"
  }

  tags = var.tags
}
