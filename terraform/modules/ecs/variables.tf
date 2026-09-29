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

variable "cron_cpu" {
  description = "CPU units for the scheduled Moodle cron task. Much lighter than the app task since it runs one PHP process and exits."
  type        = number
  default     = 256
}

variable "cron_memory" {
  type    = number
  default = 512
}

variable "cron_schedule_expression" {
  description = "EventBridge schedule expression for admin/cli/cron.php. Moodle recommends running it at least once a minute."
  type        = string
  default     = "rate(1 minute)"
}

variable "efs_file_system_id" {
  type = string
}

variable "efs_file_system_arn" {
  type = string
}

variable "efs_access_point_id" {
  type = string
}
