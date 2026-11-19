provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile

  allowed_account_ids = [
    var.allowed_account_id
  ]

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = terraform.workspace
      ManagedBy   = "Terraform"
    }
  }
}

data "aws_caller_identity" "current" {}