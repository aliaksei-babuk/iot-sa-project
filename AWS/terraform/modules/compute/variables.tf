# Compute Module - Variables

variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs"
  type        = list(string)
}

variable "lambda_timeout" {
  description = "Lambda function timeout in seconds"
  type        = number
}

variable "lambda_memory_size" {
  description = "Lambda function memory size in MB"
  type        = number
}

variable "lambda_runtime" {
  description = "Lambda runtime"
  type        = string
}

variable "fargate_cpu" {
  description = "Fargate CPU units"
  type        = number
}

variable "fargate_memory" {
  description = "Fargate memory in MB"
  type        = number
}

variable "step_functions_state_machine_name" {
  description = "Step Functions state machine name"
  type        = string
}

variable "iot_core_endpoint" {
  description = "IoT Core endpoint"
  type        = string
}

variable "kinesis_stream_arn" {
  description = "Kinesis Data Stream ARN"
  type        = string
}

variable "sqs_queue_arn" {
  description = "SQS queue ARN"
  type        = string
}

variable "dynamodb_table_arn" {
  description = "DynamoDB table ARN"
  type        = string
}

variable "rds_endpoint" {
  description = "RDS instance endpoint"
  type        = string
}

variable "s3_bucket_arn" {
  description = "S3 bucket ARN"
  type        = string
}

variable "lambda_execution_role_arn" {
  description = "Lambda execution role ARN"
  type        = string
}

variable "fargate_execution_role_arn" {
  description = "Fargate execution role ARN"
  type        = string
}

variable "step_functions_execution_role_arn" {
  description = "Step Functions execution role ARN"
  type        = string
}

variable "sns_topic_arn" {
  description = "SNS topic ARN"
  type        = string
  default     = ""
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
