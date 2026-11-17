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