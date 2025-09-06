# Monitoring Module - Variables

variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "cloudwatch_log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
}

variable "xray_tracing_enabled" {
  description = "Enable X-Ray tracing"
  type        = bool
}

variable "sns_topic_name" {
  description = "SNS topic name"
  type        = string
}

variable "lambda_function_name" {
  description = "Lambda function name"
  type        = string
}

variable "fargate_service_name" {
  description = "Fargate service name"
  type        = string
}

variable "dynamodb_table_name" {
  description = "DynamoDB table name"
  type        = string
}

variable "rds_instance_id" {
  description = "RDS instance ID"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
