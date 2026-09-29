variable "project_name" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "allowed_security_group_ids" {
  description = "Security groups allowed to reach the database on the MySQL port (typically the ECS service SG)."
  type        = list(string)
}

variable "engine_version" {
  type    = string
  default = "8.0"
}

variable "instance_class" {
  type    = string
  default = "db.t4g.micro"
}

variable "allocated_storage" {
  type    = number
  default = 20
}

variable "db_name" {
  type    = string
  default = "moodle"
}

variable "master_username" {
  type    = string
  default = "moodle_admin"
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "multi_az" {
  description = "Standby replica in a second AZ. false for dev/staging, true for prod."
  type        = bool
  default     = false
}

variable "deletion_protection" {
  description = "Blocks accidental `terraform destroy` / console deletion. false for dev/staging, true for prod."
  type        = bool
  default     = false
}
