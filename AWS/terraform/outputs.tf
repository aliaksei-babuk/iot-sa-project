# AWS IoT Sound Analytics - Outputs Configuration
# This file defines all output values for the Terraform configuration

# Networking Outputs
output "vpc_id" {
  description = "ID of the VPC"
  value       = module.networking.vpc_id
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = module.networking.vpc_cidr_block
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = module.networking.private_subnet_ids
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = module.networking.public_subnet_ids
}

output "database_subnet_ids" {
  description = "IDs of the database subnets"
  value       = module.networking.database_subnet_ids
}

output "internet_gateway_id" {
  description = "ID of the Internet Gateway"
  value       = module.networking.internet_gateway_id
}

output "nat_gateway_ids" {
  description = "IDs of the NAT Gateways"
  value       = module.networking.nat_gateway_ids
}

# Security Outputs
output "kms_key_id" {
  description = "ID of the KMS key"
  value       = module.security.kms_key_id
}

output "kms_key_arn" {
  description = "ARN of the KMS key"
  value       = module.security.kms_key_arn
}

output "lambda_execution_role_arn" {
  description = "ARN of the Lambda execution role"
  value       = module.security.lambda_execution_role_arn
}

output "fargate_execution_role_arn" {
  description = "ARN of the Fargate execution role"
  value       = module.security.fargate_execution_role_arn
}

# IoT Services Outputs
output "iot_core_endpoint" {
  description = "IoT Core endpoint"
  value       = module.iot_services.iot_core_endpoint
}

output "iot_core_arn" {
  description = "IoT Core ARN"
  value       = module.iot_services.iot_core_arn
}

output "kinesis_stream_arn" {
  description = "Kinesis Data Stream ARN"
  value       = module.iot_services.kinesis_stream_arn
}

output "kinesis_stream_name" {
  description = "Kinesis Data Stream name"
  value       = module.iot_services.kinesis_stream_name
}

output "sqs_queue_arn" {
  description = "SQS queue ARN"
  value       = module.iot_services.sqs_queue_arn
}

output "sqs_queue_url" {
  description = "SQS queue URL"
  value       = module.iot_services.sqs_queue_url
}

# Storage Outputs
output "dynamodb_table_name" {
  description = "DynamoDB table name"
  value       = module.storage.dynamodb_table_name
}

output "dynamodb_table_arn" {
  description = "DynamoDB table ARN"
  value       = module.storage.dynamodb_table_arn
}

output "rds_endpoint" {
  description = "RDS instance endpoint"
  value       = module.storage.rds_endpoint
}

output "rds_instance_id" {
  description = "RDS instance ID"
  value       = module.storage.rds_instance_id
}

output "s3_bucket_name" {
  description = "S3 bucket name"
  value       = module.storage.s3_bucket_name
}

output "s3_bucket_arn" {
  description = "S3 bucket ARN"
  value       = module.storage.s3_bucket_arn
}

output "elasticache_cluster_id" {
  description = "ElastiCache cluster ID"
  value       = module.storage.elasticache_cluster_id
}

output "elasticache_endpoint" {
  description = "ElastiCache endpoint"
  value       = module.storage.elasticache_endpoint
}

# Compute Outputs
output "lambda_function_arn" {
  description = "Lambda function ARN"
  value       = module.compute.lambda_function_arn
}

output "lambda_function_name" {
  description = "Lambda function name"
  value       = module.compute.lambda_function_name
}

output "fargate_service_arn" {
  description = "Fargate service ARN"
  value       = module.compute.fargate_service_arn
}

output "fargate_service_name" {
  description = "Fargate service name"
  value       = module.compute.fargate_service_name
}

output "step_functions_state_machine_arn" {
  description = "Step Functions state machine ARN"
  value       = module.compute.step_functions_state_machine_arn
}

# Analytics Outputs
output "sagemaker_endpoint_name" {
  description = "SageMaker endpoint name"
  value       = module.analytics.sagemaker_endpoint_name
}

output "sagemaker_endpoint_arn" {
  description = "SageMaker endpoint ARN"
  value       = module.analytics.sagemaker_endpoint_arn
}

output "kinesis_analytics_application_arn" {
  description = "Kinesis Analytics application ARN"
  value       = module.analytics.kinesis_analytics_application_arn
}

output "quicksight_dashboard_url" {
  description = "QuickSight dashboard URL"
  value       = module.analytics.quicksight_dashboard_url
}

# API Outputs
output "api_gateway_url" {
  description = "API Gateway URL"
  value       = module.api.api_gateway_url
}

output "api_gateway_id" {
  description = "API Gateway ID"
  value       = module.api.api_gateway_id
}

output "cloudfront_domain_name" {
  description = "CloudFront distribution domain name"
  value       = module.api.cloudfront_domain_name
}

output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID"
  value       = module.api.cloudfront_distribution_id
}

output "alb_dns_name" {
  description = "Application Load Balancer DNS name"
  value       = module.api.alb_dns_name
}

# Monitoring Outputs
output "cloudwatch_dashboard_url" {
  description = "CloudWatch dashboard URL"
  value       = module.monitoring.cloudwatch_dashboard_url
}

output "sns_topic_arn" {
  description = "SNS topic ARN"
  value       = module.monitoring.sns_topic_arn
}

output "xray_tracing_enabled" {
  description = "X-Ray tracing enabled status"
  value       = module.monitoring.xray_tracing_enabled
}

# Summary Outputs
output "deployment_summary" {
  description = "Deployment summary"
  value = {
    project_name    = var.project_name
    environment     = var.environment
    aws_region      = var.aws_region
    vpc_id          = module.networking.vpc_id
    iot_endpoint    = module.iot_services.iot_core_endpoint
    api_url         = module.api.api_gateway_url
    dashboard_url   = module.analytics.quicksight_dashboard_url
    monitoring_url  = module.monitoring.cloudwatch_dashboard_url
  }
}
