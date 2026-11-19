resource "terraform_data" "workspace_guard" {
  input = local.environment

  lifecycle {
    precondition {
      condition     = local.environment != "default"
      error_message = "Deployment blocked: use the dev or prod Terraform workspace."
    }

    precondition {
      condition     = contains(["dev", "prod"], local.environment)
      error_message = "Only dev and prod workspaces are permitted."
    }

    precondition {
      condition     = var.environment == terraform.workspace
      error_message = "Environment mismatch: the environment variable must match the selected Terraform workspace."
    }
  }
}