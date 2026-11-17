output "environment" {
  description = "Terraform workspace/environment"
  value       = local.environment
}

output "aws_account_id" {
  description = "AWS account used for this deployment"
  value       = data.aws_caller_identity.current.account_id
}

output "aws_region" {
  description = "AWS deployment region"
  value       = var.aws_region
}

output "instance_id" {
  description = "EC2 instance ID"
  value       = aws_instance.app.id
}

output "public_ip" {
  description = "Public IP address of the application server"
  value       = aws_instance.app.public_ip
}

output "app_url" {
  description = "Node.js application URL"
  value       = "http://${aws_instance.app.public_ip}:3000"
}

output "sns_topic_arn" {
  description = "SNS topic ARN for monitoring alerts"
  value       = aws_sns_topic.alarms.arn
}

output "dashboard_name" {
  description = "CloudWatch dashboard name"
  value       = aws_cloudwatch_dashboard.main.dashboard_name
}

output "app_log_group" {
  description = "Application CloudWatch log group"
  value       = aws_cloudwatch_log_group.app.name
}

output "alarm_event_log_group" {
  description = "CloudWatch log group for alarm events"
  value       = aws_cloudwatch_log_group.alarm_events.name
}