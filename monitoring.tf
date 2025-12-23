# CloudWatch Dashboard for Minecraft Server Monitoring
resource "aws_cloudwatch_dashboard" "minecraft_dashboard" {
  count          = var.enable_monitoring ? 1 : 0
  dashboard_name = "minecraft-server-${var.environment}"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/EC2", "CPUUtilization", "InstanceId", aws_instance.minecraft_server.id],
            [".", "NetworkIn", ".", "."],
            [".", "NetworkOut", ".", "."]
          ]
          view    = "timeSeries"
          stacked = false
          region  = data.aws_region.current.name
          title   = "EC2 Instance Metrics"
          period  = 300
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["Minecraft/Server", "mem_used_percent", "InstanceId", aws_instance.minecraft_server.id],
            [".", "disk_used_percent", ".", ".", "device", "/dev/xvda1", "fstype", "xfs", "path", "/"]
          ]
          view    = "timeSeries"
          stacked = false
          region  = data.aws_region.current.name
          title   = "System Resources"
          period  = 300
        }
      }
    ]
  })
}

# SNS Topic for alerts (optional - configure email subscription manually)
resource "aws_sns_topic" "minecraft_alerts" {
  count = var.enable_monitoring ? 1 : 0
  name  = "minecraft-server-alerts-${var.environment}"

  tags = local.common_tags
}

# CloudWatch Metric Filters for custom metrics
resource "aws_cloudwatch_log_metric_filter" "minecraft_player_count" {
  count          = var.enable_monitoring ? 1 : 0
  name           = "minecraft-player-count"
  log_group_name = aws_cloudwatch_log_group.minecraft_logs[0].name
  pattern        = "[timestamp, thread, level=\"INFO\"] players online"

  metric_transformation {
    name      = "PlayerCount"
    namespace = "Minecraft/Server"
    value     = "1"
  }
}

resource "aws_cloudwatch_log_metric_filter" "minecraft_errors" {
  count          = var.enable_monitoring ? 1 : 0
  name           = "minecraft-errors"
  log_group_name = aws_cloudwatch_log_group.minecraft_logs[0].name
  pattern        = "[timestamp, thread, level=\"ERROR\"]"

  metric_transformation {
    name      = "ErrorCount"
    namespace = "Minecraft/Server"
    value     = "1"
  }
}