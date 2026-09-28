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
