# Analytics Module - Variables

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

variable "sagemaker_instance_type" {
  description = "SageMaker instance type"
  type        = string
}

variable "sagemaker_instance_count" {
  description = "SageMaker instance count"
  type        = number
}

variable "kinesis_analytics_application_name" {
  description = "Kinesis Analytics application name"
  type        = string
}

variable "quicksight_namespace" {
  description = "QuickSight namespace"
  type        = string
}

variable "kinesis_stream_arn" {
  description = "Kinesis Data Stream ARN"
  type        = string
}

variable "s3_bucket_arn" {
  description = "S3 bucket ARN"
  type        = string
}

variable "s3_bucket_name" {
  description = "S3 bucket name"
  type        = string
}

variable "rds_endpoint" {
  description = "RDS instance endpoint"
  type        = string
}

variable "sagemaker_execution_role_arn" {
  description = "SageMaker execution role ARN"
  type        = string
}

variable "quicksight_execution_role_arn" {
  description = "QuickSight execution role ARN"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
