variable "project_name" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "public_subnet_ids" {
  type = list(string)
}

variable "health_check_path" {
  type    = string
  default = "/login/index.php"
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "acm_certificate_arn" {
  description = "ACM certificate ARN (same region as the ALB) to terminate TLS at the load balancer. Left empty by default — this project has no registered domain yet, so there is nothing to issue a real certificate for; HTTP keeps forwarding directly until one is supplied."
  type        = string
  default     = ""
}
