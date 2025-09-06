# API Module - Variables

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

variable "public_subnet_ids" {
  description = "List of public subnet IDs"
  type        = list(string)
}

variable "api_gateway_name" {
  description = "API Gateway name"
  type        = string
}

variable "api_gateway_stage_name" {
  description = "API Gateway stage name"
  type        = string
}

variable "cloudfront_price_class" {
  description = "CloudFront price class"
  type        = string
}

variable "alb_name" {
  description = "Application Load Balancer name"
  type        = string
}

variable "lambda_function_arn" {
  description = "Lambda function ARN"
  type        = string
}

variable "fargate_service_arn" {
  description = "Fargate service ARN"
  type        = string
}

variable "dynamodb_table_name" {
  description = "DynamoDB table name"
  type        = string
}

variable "s3_bucket_name" {
  description = "S3 bucket name"
  type        = string
}

variable "api_gateway_execution_role_arn" {
  description = "API Gateway execution role ARN"
  type        = string
}

variable "domain_name" {
  description = "Domain name for SSL certificate"
  type        = string
  default     = "example.com"
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
