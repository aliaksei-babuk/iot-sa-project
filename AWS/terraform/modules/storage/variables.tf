# Storage Module - Variables

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

variable "database_subnet_ids" {
  description = "List of database subnet IDs"
  type        = list(string)
}

variable "dynamodb_billing_mode" {
  description = "DynamoDB billing mode"
  type        = string
}

variable "dynamodb_read_capacity" {
  description = "DynamoDB read capacity units"
  type        = number
}

variable "dynamodb_write_capacity" {
  description = "DynamoDB write capacity units"
  type        = number
}

variable "rds_instance_class" {
  description = "RDS instance class"
  type        = string
}

variable "rds_allocated_storage" {
  description = "RDS allocated storage in GB"
  type        = number
}

variable "rds_max_allocated_storage" {
  description = "RDS maximum allocated storage in GB"
  type        = number
}

variable "rds_backup_retention_period" {
  description = "RDS backup retention period in days"
  type        = number
}

variable "rds_backup_window" {
  description = "RDS backup window"
  type        = string
}

variable "rds_maintenance_window" {
  description = "RDS maintenance window"
  type        = string
}

variable "s3_lifecycle_enabled" {
  description = "Enable S3 lifecycle policies"
  type        = bool
}

variable "s3_transition_to_ia_days" {
  description = "Days to transition to IA storage"
  type        = number
}

variable "s3_transition_to_glacier_days" {
  description = "Days to transition to Glacier storage"
  type        = number
}

variable "elasticache_node_type" {
  description = "ElastiCache node type"
  type        = string
}

variable "elasticache_num_cache_nodes" {
  description = "Number of ElastiCache nodes"
  type        = number
}

variable "kms_key_id" {
  description = "KMS key ID for encryption"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
