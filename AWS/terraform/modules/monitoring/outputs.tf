# Monitoring Module - Outputs

output "cloudwatch_dashboard_url" {
  description = "CloudWatch dashboard URL"
  value       = "https://${data.aws_region.current.name}.console.aws.amazon.com/cloudwatch/home?region=${data.aws_region.current.name}#dashboards:name=${aws_cloudwatch_dashboard.main.dashboard_name}"
}

output "sns_topic_arn" {
  description = "SNS topic ARN"
  value       = aws_sns_topic.alerts.arn
}

output "sns_topic_name" {
  description = "SNS topic name"
  value       = aws_sns_topic.alerts.name
}

output "lambda_log_group_name" {
  description = "Lambda log group name"
  value       = aws_cloudwatch_log_group.lambda.name
}

output "ecs_log_group_name" {
  description = "ECS log group name"
  value       = aws_cloudwatch_log_group.ecs.name
}

output "api_gateway_log_group_name" {
  description = "API Gateway log group name"
  value       = aws_cloudwatch_log_group.api_gateway.name
}

output "lambda_errors_alarm_arn" {
  description = "Lambda errors alarm ARN"
  value       = aws_cloudwatch_metric_alarm.lambda_errors.arn
}

output "lambda_duration_alarm_arn" {
  description = "Lambda duration alarm ARN"
  value       = aws_cloudwatch_metric_alarm.lambda_duration.arn
}

output "dynamodb_throttles_alarm_arn" {
  description = "DynamoDB throttles alarm ARN"
  value       = aws_cloudwatch_metric_alarm.dynamodb_throttles.arn
}

output "rds_cpu_alarm_arn" {
  description = "RDS CPU alarm ARN"
  value       = aws_cloudwatch_metric_alarm.rds_cpu.arn
}

output "xray_tracing_enabled" {
  description = "X-Ray tracing enabled status"
  value       = var.xray_tracing_enabled
}

output "xray_sampling_rule_arn" {
  description = "X-Ray sampling rule ARN"
  value       = var.xray_tracing_enabled ? aws_xray_sampling_rule.main[0].arn : null
}

# Data source for current region
data "aws_region" "current" {}
