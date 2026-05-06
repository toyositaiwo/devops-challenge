resource "aws_cloudwatch_log_group" "ecs" {
  name              = "/ecs/${var.project}-${var.environment}"
  retention_in_days = 30
  tags = merge(var.tags, {
    Name = "/ecs/${var.project}-${var.environment}"
  })
}

resource "aws_cloudwatch_metric_alarm" "alb_5xx" {
  alarm_name          = "${var.project}-${var.environment}-alb-5xx"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "HTTPCode_ELB_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Sum"
  threshold           = 10
  alarm_description   = "ALB 5xx errors exceeded threshold"
  treat_missing_data  = "notBreaching"
  dimensions = {
    LoadBalancer = var.alb_arn
  }
  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  alarm_name          = "${var.project}-${var.environment}-ecs-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = 60
  statistic           = "Average"
  threshold           = 85
  alarm_description   = "ECS CPU utilization is high"
  treat_missing_data  = "notBreaching"
  dimensions = {
    ClusterName = var.cluster_name
    ServiceName = var.service_name
  }
  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "memory_high" {
  alarm_name          = "${var.project}-${var.environment}-ecs-memory-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "MemoryUtilization"
  namespace           = "AWS/ECS"
  period              = 60
  statistic           = "Average"
  threshold           = 85
  alarm_description   = "ECS Memory utilization is high"
  treat_missing_data  = "notBreaching"
  dimensions = {
    ClusterName = var.cluster_name
    ServiceName = var.service_name
  }
  tags = var.tags
}

resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "${var.project}-${var.environment}"
  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        properties = {
          title   = "ECS CPU & Memory Utilization"
          region  = var.aws_region
          period  = 60
          stat    = "Average"
          view    = "timeSeries"
          metrics = [
            ["AWS/ECS", "CPUUtilization", "ClusterName", var.cluster_name, "ServiceName", var.service_name],
            ["AWS/ECS", "MemoryUtilization", "ClusterName", var.cluster_name, "ServiceName", var.service_name]
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
          title   = "ALB Requests & Errors"
          region  = var.aws_region
          period  = 60
          stat    = "Sum"
          view    = "timeSeries"
          metrics = [
            ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", var.alb_arn],
            ["AWS/ApplicationELB", "HTTPCode_ELB_5XX_Count", "LoadBalancer", var.alb_arn],
            ["AWS/ApplicationELB", "HTTPCode_ELB_4XX_Count", "LoadBalancer", var.alb_arn]
          ]
        }
      }
    ]
  })
}