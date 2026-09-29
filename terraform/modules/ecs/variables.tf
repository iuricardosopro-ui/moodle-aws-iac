variable "project_name" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "alb_security_group_id" {
  type = string
}

variable "service_security_group_id" {
  description = "Security group attached to the ECS service's ENIs. Created in the root module (not here) so it can also be referenced by the RDS module's ingress rule, avoiding a module dependency cycle between ECS and RDS."
  type        = string
}

variable "target_group_arn" {
  type = string
}

variable "ecr_repository_url" {
  type = string
}

variable "image_tag" {
  description = "Image tag to deploy. Passed in by the CI/CD pipeline on every release."
  type        = string
  default     = "latest"
}

variable "db_endpoint" {
  type = string
}

variable "db_name" {
  type = string
}

variable "db_secret_arn" {
  type = string
}

variable "cpu" {
  type    = number
  default = 512
}

variable "memory" {
  type    = number
  default = 1024
}

variable "desired_count" {
  type    = number
  default = 1
}

variable "tags" {
  type    = map(string)
  default = {}
}
