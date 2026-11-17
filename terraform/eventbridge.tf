
resource "aws_cloudwatch_event_rule" "alarm_state" {
  name        = "${local.name_prefix}-alarm-state"
  description = "Capture CloudWatch alarm state changes for ${local.environment}"

  event_pattern = jsonencode({
    source = ["aws.cloudwatch"]

    "detail-type" = [
      "CloudWatch Alarm State Change"
    ]

    resources = [
      aws_cloudwatch_metric_alarm.app_errors.arn,
      aws_cloudwatch_metric_alarm.cpu.arn
    ]

    detail = {
      state = {
        value = ["ALARM"]
      }
    }
  })

  tags = local.common_tags

  depends_on = [terraform_data.workspace_guard]
}

resource "aws_cloudwatch_log_resource_policy" "eventbridge" {
  policy_name = "${local.name_prefix}-eventbridge-policy"

  policy_document = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Sid    = "EventBridgeWriteLogs"
        Effect = "Allow"

        Principal = {
          Service = "events.amazonaws.com"
        }

        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]

        Resource = "${aws_cloudwatch_log_group.alarm_events.arn}:*"

        Condition = {
          ArnEquals = {
            "aws:SourceArn" = aws_cloudwatch_event_rule.alarm_state.arn
          }
        }
      }
    ]
  })

  depends_on = [terraform_data.workspace_guard]
}

resource "aws_cloudwatch_event_target" "alarm_logs" {
  rule      = aws_cloudwatch_event_rule.alarm_state.name
  target_id = "AlarmEventsToCloudWatchLogs"

  arn = aws_cloudwatch_log_group.alarm_events.arn

  depends_on = [
    terraform_data.workspace_guard,
    aws_cloudwatch_log_resource_policy.eventbridge
  ]
}
