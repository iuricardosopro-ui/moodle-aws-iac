variable "domain_name" {
  description = "Custom domain to point at CloudFront, e.g. moodle.example.com. Leave empty to skip DNS entirely."
  type        = string
  default     = ""
}

variable "route53_zone_id" {
  description = "Existing hosted zone to create records in. Leave empty to skip DNS entirely."
  type        = string
  default     = ""
}

variable "cloudfront_domain_name" {
  type    = string
  default = ""
}

variable "cloudfront_hosted_zone_id" {
  type    = string
  default = ""
}

variable "create_www_record" {
  type    = bool
  default = true
}
