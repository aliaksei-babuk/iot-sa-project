# AWS IoT Sound Analytics - Variables Configuration
# This file defines all input variables for the Terraform configuration

# General Configuration
variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "iot-sound-analytics"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "owner" {
  description = "Owner of the resources"
  type        = string
  default     = "iot-team"
}

# Networking Configuration
variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
  default     = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]
}

variable "database_subnet_cidrs" {
  description = "CIDR blocks for database subnets"
  type        = list(string)
  default     = ["10.0.21.0/24", "10.0.22.0/24", "10.0.23.0/24"]
}

# Security Configuration
variable "kms_key_rotation" {
  description = "Enable KMS key rotation"
  type        = bool
  default     = true
}

variable "admin_users" {
  description = "List of admin users"
  type        = list(string)
  default     = []
}

# IoT Services Configuration
variable "iot_thing_type_name" {
  description = "Name of the IoT thing type"
  type        = string
  default     = "SoundSensor"
}

variable "iot_policy_name" {
  description = "Name of the IoT policy"
  type        = string
  default     = "SoundSensorPolicy"
}

variable "kinesis_shard_count" {
  description = "Number of Kinesis shards"
  type        = number
  default     = 2
}

variable "kinesis_retention_hours" {
  description = "Kinesis data retention in hours"
  type        = number
  default     = 24
}

variable "sqs_visibility_timeout_seconds" {
  description = "SQS visibility timeout in seconds"
  type        = number
  default     = 30
}

variable "sqs_message_retention_seconds" {
  description = "SQS message retention in seconds"
  type        = number
  default     = 1209600 # 14 days
}

# Storage Configuration
variable "dynamodb_billing_mode" {
  description = "DynamoDB billing mode"
  type        = string
  default     = "PAY_PER_REQUEST"
  validation {
    condition     = contains(["PROVISIONED", "PAY_PER_REQUEST"], var.dynamodb_billing_mode)
    error_message = "DynamoDB billing mode must be either PROVISIONED or PAY_PER_REQUEST."
  }
}

variable "dynamodb_read_capacity" {
  description = "DynamoDB read capacity units"
  type        = number
  default     = 5
}

variable "dynamodb_write_capacity" {
  description = "DynamoDB write capacity units"
  type        = number
  default     = 5
}

variable "rds_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "rds_allocated_storage" {
  description = "RDS allocated storage in GB"
  type        = number
  default     = 20
}

variable "rds_max_allocated_storage" {
  description = "RDS maximum allocated storage in GB"
  type        = number
  default     = 100
}

variable "rds_backup_retention_period" {
  description = "RDS backup retention period in days"
  type        = number
  default     = 7
}

variable "rds_backup_window" {
  description = "RDS backup window"
  type        = string
  default     = "03:00-04:00"
}

variable "rds_maintenance_window" {
  description = "RDS maintenance window"
  type        = string
  default     = "sun:04:00-sun:05:00"
}

variable "s3_lifecycle_enabled" {
  description = "Enable S3 lifecycle policies"
  type        = bool
  default     = true
}

variable "s3_transition_to_ia_days" {
  description = "Days to transition to IA storage"
  type        = number
  default     = 30
}

variable "s3_transition_to_glacier_days" {
  description = "Days to transition to Glacier storage"
  type        = number
  default     = 90
}

variable "elasticache_node_type" {
  description = "ElastiCache node type"
  type        = string
  default     = "cache.t3.micro"
}

variable "elasticache_num_cache_nodes" {
  description = "Number of ElastiCache nodes"
  type        = number
  default     = 1
}

# Compute Configuration
variable "lambda_timeout" {
  description = "Lambda function timeout in seconds"
  type        = number
  default     = 30
}

variable "lambda_memory_size" {
  description = "Lambda function memory size in MB"
  type        = number
  default     = 512
}

variable "lambda_runtime" {
  description = "Lambda runtime"
  type        = string
  default     = "python3.9"
}

variable "fargate_cpu" {
  description = "Fargate CPU units"
  type        = number
  default     = 256
}

variable "fargate_memory" {
  description = "Fargate memory in MB"
  type        = number
  default     = 512
}

variable "step_functions_state_machine_name" {
  description = "Step Functions state machine name"
  type        = string
  default     = "SoundAnalyticsWorkflow"
}

# Analytics Configuration
variable "sagemaker_instance_type" {
  description = "SageMaker instance type"
  type        = string
  default     = "ml.t3.medium"
}

variable "sagemaker_instance_count" {
  description = "SageMaker instance count"
  type        = number
  default     = 1
}

variable "kinesis_analytics_application_name" {
  description = "Kinesis Analytics application name"
  type        = string
  default     = "SoundAnalyticsApp"
}

variable "quicksight_namespace" {
  description = "QuickSight namespace"
  type        = string
  default     = "iot-sound-analytics"
}

# API Configuration
variable "api_gateway_name" {
  description = "API Gateway name"
  type        = string
  default     = "iot-sound-analytics-api"
}

variable "api_gateway_stage_name" {
  description = "API Gateway stage name"
  type        = string
  default     = "v1"
}

variable "cloudfront_price_class" {
  description = "CloudFront price class"
  type        = string
  default     = "PriceClass_100"
}

variable "alb_name" {
  description = "Application Load Balancer name"
  type        = string
  default     = "iot-sound-analytics-alb"
}

# Monitoring Configuration
variable "cloudwatch_log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 30
}

variable "xray_tracing_enabled" {
  description = "Enable X-Ray tracing"
  type        = bool
  default     = true
}

variable "sns_topic_name" {
  description = "SNS topic name"
  type        = string
  default     = "iot-sound-analytics-alerts"
}
