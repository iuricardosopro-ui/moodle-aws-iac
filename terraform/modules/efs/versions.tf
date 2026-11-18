# Version constraints for this module. They mirror the root module
# (environments/app/versions.tf) so the module states what it needs on its
# own, which is what tflint's terraform_required_* rules check for.
terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
