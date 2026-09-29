variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "owner" {
  description = "Person or team accountable for this environment's cost and operation."
  type        = string
}

variable "cost_center" {
  description = "Cost allocation tag used for AWS Cost Explorer / budget reports."
  type        = string
  default     = "portfolio"
}

variable "extra_tags" {
  description = "Additional tags merged on top of the standard set, for a resource or environment that needs something extra without changing the shared convention."
  type        = map(string)
  default     = {}
}
