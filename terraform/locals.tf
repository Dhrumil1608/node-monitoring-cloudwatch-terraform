locals {
  environment = terraform.workspace

  name_prefix = "${var.project_name}-${local.environment}"

  metric_namespace = "Application/NodeApp/${local.environment}"

  common_tags = {
    Project     = var.project_name
    Environment = local.environment
    ManagedBy   = "Terraform"
  }
}
