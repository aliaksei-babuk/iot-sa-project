# AWS IoT Sound Analytics - Main Terraform Configuration
# This file defines the main infrastructure for the serverless sound analytics platform

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
      Owner       = var.owner
    }
  }
}

# Data sources
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
data "aws_availability_zones" "available" {
  state = "available"
}

# Local values
locals {
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
    Owner       = var.owner
  }
  
  # Naming convention
  name_prefix = "${var.project_name}-${var.environment}"
  
  # Availability zones
  azs = slice(data.aws_availability_zones.available.names, 0, 3)
}

# Networking Module
module "networking" {
  source = "./modules/networking"
  
  project_name = var.project_name
  environment  = var.environment
  vpc_cidr     = var.vpc_cidr
  azs          = local.azs
  
  # Public subnet CIDRs
  public_subnet_cidrs = var.public_subnet_cidrs
  
  # Private subnet CIDRs
  private_subnet_cidrs = var.private_subnet_cidrs
  
  # Database subnet CIDRs
  database_subnet_cidrs = var.database_subnet_cidrs
  
  tags = local.common_tags
}

# Security Module
module "security" {
  source = "./modules/security"
  
  project_name = var.project_name
  environment  = var.environment
  vpc_id       = module.networking.vpc_id
  
  # KMS configuration
  kms_key_rotation = var.kms_key_rotation
  
  # IAM configuration
  admin_users = var.admin_users
  
  tags = local.common_tags
}

# IoT Services Module
module "iot_services" {
  source = "./modules/iot_services"
  
  project_name = var.project_name
  environment  = var.environment
  vpc_id       = module.networking.vpc_id
  private_subnet_ids = module.networking.private_subnet_ids
  
  # IoT Core configuration
  iot_thing_type_name = var.iot_thing_type_name
  iot_policy_name     = var.iot_policy_name
  
  # Kinesis configuration
  kinesis_shard_count = var.kinesis_shard_count
  kinesis_retention_hours = var.kinesis_retention_hours
  
  # SQS configuration
  sqs_visibility_timeout_seconds = var.sqs_visibility_timeout_seconds
  sqs_message_retention_seconds  = var.sqs_message_retention_seconds
  
  tags = local.common_tags
}

# Storage Module
module "storage" {
  source = "./modules/storage"
  
  project_name = var.project_name
  environment  = var.environment
  vpc_id       = module.networking.vpc_id
  private_subnet_ids = module.networking.private_subnet_ids
  database_subnet_ids = module.networking.database_subnet_ids
  
  # DynamoDB configuration
  dynamodb_billing_mode = var.dynamodb_billing_mode
  dynamodb_read_capacity = var.dynamodb_read_capacity
  dynamodb_write_capacity = var.dynamodb_write_capacity
  
  # RDS configuration
  rds_instance_class = var.rds_instance_class
  rds_allocated_storage = var.rds_allocated_storage
  rds_max_allocated_storage = var.rds_max_allocated_storage
  rds_backup_retention_period = var.rds_backup_retention_period
  rds_backup_window = var.rds_backup_window
  rds_maintenance_window = var.rds_maintenance_window
  
  # S3 configuration
  s3_lifecycle_enabled = var.s3_lifecycle_enabled
  s3_transition_to_ia_days = var.s3_transition_to_ia_days
  s3_transition_to_glacier_days = var.s3_transition_to_glacier_days
  
  # ElastiCache configuration
  elasticache_node_type = var.elasticache_node_type
  elasticache_num_cache_nodes = var.elasticache_num_cache_nodes
  
  # KMS key for encryption
  kms_key_id = module.security.kms_key_id
  
  tags = local.common_tags
}

# Compute Module
module "compute" {
  source = "./modules/compute"
  
  project_name = var.project_name
  environment  = var.environment
  vpc_id       = module.networking.vpc_id
  private_subnet_ids = module.networking.private_subnet_ids
  
  # Lambda configuration
  lambda_timeout = var.lambda_timeout
  lambda_memory_size = var.lambda_memory_size
  lambda_runtime = var.lambda_runtime
  
  # Fargate configuration
  fargate_cpu = var.fargate_cpu
  fargate_memory = var.fargate_memory
  
  # Step Functions configuration
  step_functions_state_machine_name = var.step_functions_state_machine_name
  
  # Dependencies
  iot_core_endpoint = module.iot_services.iot_core_endpoint
  kinesis_stream_arn = module.iot_services.kinesis_stream_arn
  sqs_queue_arn = module.iot_services.sqs_queue_arn
  dynamodb_table_arn = module.storage.dynamodb_table_arn
  rds_endpoint = module.storage.rds_endpoint
  s3_bucket_arn = module.storage.s3_bucket_arn
  
  # IAM roles
  lambda_execution_role_arn = module.security.lambda_execution_role_arn
  fargate_execution_role_arn = module.security.fargate_execution_role_arn
  step_functions_execution_role_arn = module.security.step_functions_execution_role_arn
  
  tags = local.common_tags
}

# Analytics Module
module "analytics" {
  source = "./modules/analytics"
  
  project_name = var.project_name
  environment  = var.environment
  vpc_id       = module.networking.vpc_id
  private_subnet_ids = module.networking.private_subnet_ids
  
  # SageMaker configuration
  sagemaker_instance_type = var.sagemaker_instance_type
  sagemaker_instance_count = var.sagemaker_instance_count
  
  # Kinesis Analytics configuration
  kinesis_analytics_application_name = var.kinesis_analytics_application_name
  
  # QuickSight configuration
  quicksight_namespace = var.quicksight_namespace
  
  # Dependencies
  kinesis_stream_arn = module.iot_services.kinesis_stream_arn
  s3_bucket_arn = module.storage.s3_bucket_arn
  rds_endpoint = module.storage.rds_endpoint
  
  # IAM roles
  sagemaker_execution_role_arn = module.security.sagemaker_execution_role_arn
  quicksight_execution_role_arn = module.security.quicksight_execution_role_arn
  
  tags = local.common_tags
}

# API Module
module "api" {
  source = "./modules/api"
  
  project_name = var.project_name
  environment  = var.environment
  vpc_id       = module.networking.vpc_id
  private_subnet_ids = module.networking.private_subnet_ids
  public_subnet_ids = module.networking.public_subnet_ids
  
  # API Gateway configuration
  api_gateway_name = var.api_gateway_name
  api_gateway_stage_name = var.api_gateway_stage_name
  
  # CloudFront configuration
  cloudfront_price_class = var.cloudfront_price_class
  
  # ALB configuration
  alb_name = var.alb_name
  
  # Dependencies
  lambda_function_arn = module.compute.lambda_function_arn
  fargate_service_arn = module.compute.fargate_service_arn
  dynamodb_table_name = module.storage.dynamodb_table_name
  s3_bucket_name = module.storage.s3_bucket_name
  
  # IAM roles
  api_gateway_execution_role_arn = module.security.api_gateway_execution_role_arn
  
  tags = local.common_tags
}

# Monitoring Module
module "monitoring" {
  source = "./modules/monitoring"
  
  project_name = var.project_name
  environment  = var.environment
  
  # CloudWatch configuration
  cloudwatch_log_retention_days = var.cloudwatch_log_retention_days
  
  # X-Ray configuration
  xray_tracing_enabled = var.xray_tracing_enabled
  
  # SNS configuration
  sns_topic_name = var.sns_topic_name
  
  # Dependencies
  lambda_function_name = module.compute.lambda_function_name
  fargate_service_name = module.compute.fargate_service_name
  dynamodb_table_name = module.storage.dynamodb_table_name
  rds_instance_id = module.storage.rds_instance_id
  
  tags = local.common_tags
}

# Outputs
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

output "iot_core_endpoint" {
  description = "IoT Core endpoint"
  value       = module.iot_services.iot_core_endpoint
}

output "kinesis_stream_arn" {
  description = "Kinesis Data Stream ARN"
  value       = module.iot_services.kinesis_stream_arn
}

output "dynamodb_table_name" {
  description = "DynamoDB table name"
  value       = module.storage.dynamodb_table_name
}

output "rds_endpoint" {
  description = "RDS instance endpoint"
  value       = module.storage.rds_endpoint
}

output "s3_bucket_name" {
  description = "S3 bucket name"
  value       = module.storage.s3_bucket_name
}

output "api_gateway_url" {
  description = "API Gateway URL"
  value       = module.api.api_gateway_url
}

output "cloudfront_domain_name" {
  description = "CloudFront distribution domain name"
  value       = module.api.cloudfront_domain_name
}

output "lambda_function_arn" {
  description = "Lambda function ARN"
  value       = module.compute.lambda_function_arn
}

output "sagemaker_endpoint_name" {
  description = "SageMaker endpoint name"
  value       = module.analytics.sagemaker_endpoint_name
}

output "quicksight_dashboard_url" {
  description = "QuickSight dashboard URL"
  value       = module.analytics.quicksight_dashboard_url
}

output "cloudwatch_dashboard_url" {
  description = "CloudWatch dashboard URL"
  value       = module.monitoring.cloudwatch_dashboard_url
}