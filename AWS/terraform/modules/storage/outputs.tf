# Storage Module - Outputs

output "dynamodb_table_name" {
  description = "DynamoDB table name"
  value       = aws_dynamodb_table.main.name
}

output "dynamodb_table_arn" {
  description = "DynamoDB table ARN"
  value       = aws_dynamodb_table.main.arn
}

output "dynamodb_table_id" {
  description = "DynamoDB table ID"
  value       = aws_dynamodb_table.main.id
}

output "rds_endpoint" {
  description = "RDS instance endpoint"
  value       = aws_db_instance.main.endpoint
}

output "rds_instance_id" {
  description = "RDS instance ID"
  value       = aws_db_instance.main.id
}

output "rds_instance_arn" {
  description = "RDS instance ARN"
  value       = aws_db_instance.main.arn
}

output "rds_port" {
  description = "RDS instance port"
  value       = aws_db_instance.main.port
}

output "rds_database_name" {
  description = "RDS database name"
  value       = aws_db_instance.main.db_name
}

output "rds_username" {
  description = "RDS master username"
  value       = aws_db_instance.main.username
}

output "s3_bucket_name" {
  description = "S3 bucket name"
  value       = aws_s3_bucket.main.bucket
}

output "s3_bucket_arn" {
  description = "S3 bucket ARN"
  value       = aws_s3_bucket.main.arn
}

output "s3_bucket_domain_name" {
  description = "S3 bucket domain name"
  value       = aws_s3_bucket.main.bucket_domain_name
}

output "elasticache_cluster_id" {
  description = "ElastiCache cluster ID"
  value       = aws_elasticache_replication_group.main.id
}

output "elasticache_endpoint" {
  description = "ElastiCache endpoint"
  value       = aws_elasticache_replication_group.main.primary_endpoint_address
}

output "elasticache_port" {
  description = "ElastiCache port"
  value       = aws_elasticache_replication_group.main.port
}

output "elasticache_arn" {
  description = "ElastiCache ARN"
  value       = aws_elasticache_replication_group.main.arn
}

output "db_password" {
  description = "RDS database password"
  value       = random_password.db_password.result
  sensitive   = true
}
