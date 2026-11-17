resource "aws_cloudwatch_log_group" "app" {
  name              = "/aws/ec2/${local.name_prefix}/app"
  retention_in_days = var.app_log_retention_days

  tags = local.common_tags

  depends_on = [terraform_data.workspace_guard]
}

resource "aws_cloudwatch_log_group" "alarm_events" {
  name              = "/aws/events/${local.name_prefix}-alarms"
  retention_in_days = var.event_log_retention_days

  tags = local.common_tags

  depends_on = [terraform_data.workspace_guard]
}

resource "aws_cloudwatch_log_metric_filter" "errors" {
  name           = "${local.name_prefix}-error-filter"
  log_group_name = aws_cloudwatch_log_group.app.name

  pattern = "{ $.level = \"ERROR\" }"

  metric_transformation {
    name          = "ErrorCount"
    namespace     = local.metric_namespace
    value         = "1"
    default_value = 0
  }

  depends_on = [terraform_data.workspace_guard]
}
