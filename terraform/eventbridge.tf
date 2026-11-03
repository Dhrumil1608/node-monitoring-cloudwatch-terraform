
resource "aws_cloudwatch_event_rule" "alarm_state" {
  name        = "${var.project_name}-alarm-state"
  description = "Capture all state changes for the application error and CPU alarms"

  event_pattern = jsonencode({
    source = [
      "aws.cloudwatch"
    ]

    "detail-type" = [
      "CloudWatch Alarm State Change"
    ]

    resources = [
      aws_cloudwatch_metric_alarm.app_errors.arn,
      aws_cloudwatch_metric_alarm.cpu.arn
    ]

    detail = {
      state = {
        value = [
          "ALARM",
          "OK",
          "INSUFFICIENT_DATA"
        ]
      }
    }
  })
}

resource "aws_cloudwatch_log_resource_policy" "eventbridge" {
  policy_name = "${var.project_name}-eventbridge-policy"

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
}

resource "aws_cloudwatch_event_target" "alarm_logs" {
  rule      = aws_cloudwatch_event_rule.alarm_state.name
  target_id = "AlarmEventsToCloudWatchLogs"

  arn = aws_cloudwatch_log_group.alarm_events.arn

  depends_on = [
    aws_cloudwatch_log_resource_policy.eventbridge
  ]
}
