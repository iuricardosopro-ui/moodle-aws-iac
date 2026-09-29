variable "project_name" {
  type = string
}

variable "alb_dns_name" {
  type = string
}

variable "price_class" {
  description = "PriceClass_100 (US/Canada/Europe only) keeps cost down for a portfolio project; PriceClass_All for real global reach."
  type        = string
  default     = "PriceClass_100"
}

variable "acm_certificate_arn" {
  description = "ACM certificate (must be in us-east-1) for a custom domain. Left empty to use the default *.cloudfront.net certificate."
  type        = string
  default     = ""
}

variable "tags" {
  type    = map(string)
  default = {}
}
