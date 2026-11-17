resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "${local.name_prefix}-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6

        properties = {
          title  = "${local.environment} EC2 CPU Utilization"
          view   = "timeSeries"
          region = var.aws_region
          period = 60

          metrics = [
            [
              "AWS/EC2",
              "CPUUtilization",
              "InstanceId",
              aws_instance.app.id
            ]
          ]
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6

        properties = {
          title  = "${local.environment} Memory Utilization"
          view   = "timeSeries"
          region = var.aws_region
          period = 60

          metrics = [
            [
              "CWAgent",
              "mem_used_percent",
              "InstanceId",
              aws_instance.app.id
            ]
          ]
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6

        properties = {
          title  = "${local.environment} Disk Utilization"
          view   = "timeSeries"
          region = var.aws_region
          period = 60

          metrics = [
            [
              "CWAgent",
              "disk_used_percent",
              "InstanceId",
              aws_instance.app.id
            ]
          ]
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 6
        width  = 12
        height = 6

        properties = {
          title  = "${local.environment} Application Error Count"
          view   = "timeSeries"
          region = var.aws_region
          period = 300
          stat   = "Sum"

          metrics = [
            [
              local.metric_namespace,
              "ErrorCount"
            ]
          ]
        }
      }
    ]
  })

  depends_on = [terraform_data.workspace_guard]
}
