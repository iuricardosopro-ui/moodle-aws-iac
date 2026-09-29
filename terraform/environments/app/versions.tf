terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }

  # Remote state backend — S3 bucket + DynamoDB lock table created out-of-band.
  # Left commented so the project runs out of the box with local state; uncomment
  # and fill in your own bucket/table before using this in a shared environment.
  #
  # backend "s3" {
  #   bucket         = "REPLACE-WITH-YOUR-STATE-BUCKET"
  #   key            = "moodle-aws-iac/dev/terraform.tfstate"
  #   region         = "us-east-1"
  #   dynamodb_table = "REPLACE-WITH-YOUR-LOCK-TABLE"
  #   encrypt        = true
  # }
}

provider "aws" {
  region = var.aws_region

  # Tags are applied explicitly per resource via module.tags.tags in main.tf
  # (see terraform/modules/tags). A provider-level default_tags block isn't
  # needed on top of that, and an earlier version of this file referenced an
  # undeclared `local.common_tags` here — caught by `terraform validate`.
}

# Select the environment before plan/apply:
#   terraform workspace new dev      # first time only
#   terraform workspace select dev
#   terraform plan  -var-file=vars/dev.tfvars
#   terraform apply -var-file=vars/dev.tfvars
#
# Repeat with staging.tfvars / prod.tfvars in their own workspaces
# (staging / prod). Each workspace keeps a fully separate state file,
# so a mistake in one environment's plan can never touch another's.
