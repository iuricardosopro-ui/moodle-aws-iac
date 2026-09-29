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

  default_tags {
    tags = local.common_tags
  }
}
