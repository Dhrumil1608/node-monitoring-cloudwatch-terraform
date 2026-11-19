
variable "aws_region" {
  description = "AWS deployment region"
  type        = string
}

variable "project_name" {
  description = "Base project name"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
}

variable "alarm_email" {
  description = "Email for SNS notifications"
  type        = string
  sensitive   = true
}

variable "app_log_retention_days" {
  description = "Application log retention in days"
  type        = number
}

variable "event_log_retention_days" {
  description = "Event log retention in days"
  type        = number
}

variable "aws_profile" {
  description = "AWS CLI profile used for deployment"
  type        = string
}

variable "allowed_account_id" {
  description = "AWS account ID permitted for deployment"
  type        = string

  validation {
    condition     = can(regex("^[0-9]{12}$", var.allowed_account_id))
    error_message = "The AWS account ID must contain exactly 12 digits."
  }
}

variable "environment" {
  description = "Deployment environment; must match the Terraform workspace"
  type        = string

  validation {
    condition     = contains(["dev", "prod"], var.environment)
    error_message = "Environment must be dev or prod."
  }
}
