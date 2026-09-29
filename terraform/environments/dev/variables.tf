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
