variable "project_name" {
  type = string
}

variable "aws_region" {
  type = string
}

variable "ecs_cluster_name" {
  type = string
}

variable "ecs_service_name" {
  type = string
}

variable "alb_arn_suffix" {
  type = string
}

variable "target_group_arn_suffix" {
  type = string
}

variable "rds_instance_id" {
  type = string
}

variable "alarm_email" {
  description = "If set, subscribes this address to the SNS topic that alarms publish to. Left empty by default so a fresh apply does not require confirming a subscription."
  type        = string
  default     = ""
}

variable "tags" {
  type    = map(string)
  default = {}
}
