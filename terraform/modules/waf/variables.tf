variable "project_name" {
  type = string
}

variable "scope" {
  description = "REGIONAL (for an ALB) or CLOUDFRONT. A CLOUDFRONT-scoped Web ACL must be created with a provider in us-east-1 — fine here since this project's default aws_region already is us-east-1, but worth knowing if that ever changes."
  type        = string

  validation {
    condition     = contains(["REGIONAL", "CLOUDFRONT"], var.scope)
    error_message = "scope must be REGIONAL or CLOUDFRONT."
  }
}

variable "scope_suffix" {
  description = "Short suffix identifying what this Web ACL protects (e.g. \"alb\", \"cdn\"), used in resource/metric names."
  type        = string
}

variable "rate_limit" {
  description = "Max requests from a single IP per 5-minute window before it is blocked."
  type        = number
  default     = 2000
}

variable "tags" {
  type    = map(string)
  default = {}
}
