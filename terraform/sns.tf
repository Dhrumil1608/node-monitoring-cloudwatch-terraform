resource "aws_sns_topic" "alarms" {
  name = "${local.name_prefix}-alerts"

  tags = local.common_tags

  depends_on = [terraform_data.workspace_guard]
}

resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.alarms.arn
  protocol  = "email"
  endpoint  = var.alarm_email

  depends_on = [terraform_data.workspace_guard]
}
