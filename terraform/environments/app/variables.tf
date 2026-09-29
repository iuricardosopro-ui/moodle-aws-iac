variable "project_name" {
  type    = string
  default = "moodle-portfolio"
}

variable "environment" {
  type    = string
  default = "dev"
}

variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "azs" {
  type    = list(string)
  default = ["us-east-1a", "us-east-1b"]
}

variable "vpc_cidr" {
  type    = string
  default = "10.20.0.0/16"
}

variable "public_subnet_cidrs" {
  type    = list(string)
  default = ["10.20.0.0/24", "10.20.1.0/24"]
}

variable "private_subnet_cidrs" {
  type    = list(string)
  default = ["10.20.10.0/24", "10.20.11.0/24"]
}

variable "moodle_image_tag" {
  description = "Tag pushed by the CI/CD pipeline (git SHA). Defaults to 'latest' for a first manual apply."
  type        = string
  default     = "latest"
}

variable "owner" {
  description = "Person or team accountable for this environment's cost and operation (FinOps tagging)."
  type        = string
  default     = "iuri-cardoso"
}

variable "cost_center" {
  description = "Cost allocation tag used for AWS Cost Explorer / budget reports (FinOps tagging)."
  type        = string
  default     = "portfolio"
}

variable "alarm_email" {
  description = "Email address subscribed to CloudWatch alarm notifications. Empty by default (no subscription created on a fresh apply)."
  type        = string
  default     = ""
}

variable "enable_cdn" {
  description = "Provisions a CloudFront distribution in front of the ALB. Off by default for dev; staging/prod turn it on via their own tfvars."
  type        = bool
  default     = false
}

variable "domain_name" {
  description = "Custom domain for Route53 + CloudFront. Empty by default — this portfolio project does not own a registered domain, so the app is reached via the ALB/CloudFront AWS-provided DNS name instead."
  type        = string
  default     = ""
}

variable "route53_zone_id" {
  description = "Existing Route53 hosted zone ID for domain_name. Empty by default (see domain_name)."
  type        = string
  default     = ""
}

variable "desired_count" {
  description = "Number of ECS tasks to run. 1 for dev, 2+ for staging/prod (requires the shared EFS storage already in place)."
  type        = number
  default     = 1
}

variable "db_instance_class" {
  type    = string
  default = "db.t4g.micro"
}

variable "db_multi_az" {
  type    = bool
  default = false
}

variable "db_deletion_protection" {
  type    = bool
  default = false
}
