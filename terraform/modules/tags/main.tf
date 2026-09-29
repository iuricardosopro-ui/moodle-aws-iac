# Centralizes the tagging strategy so every resource across every module
# carries the same set of keys. This is what makes cost allocation
# reports (AWS Cost Explorer, Cost and Usage Report, budgets) actually
# usable: you can group spend by Project, Environment, CostCenter or
# Owner without hunting for inconsistently-tagged resources.
locals {
  standard_tags = merge(
    {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "terraform"
      CostCenter  = var.cost_center
      Owner       = var.owner
    },
    var.extra_tags
  )
}
