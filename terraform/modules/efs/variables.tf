variable "project_name" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "ecs_security_group_id" {
  description = "Security group of the ECS service that is allowed to mount this filesystem over NFS."
  type        = string
}

variable "tags" {
  type    = map(string)
  default = {}
}
