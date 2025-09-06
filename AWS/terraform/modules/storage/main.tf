# Storage Module - Main Configuration
# This module creates DynamoDB, RDS, S3, and ElastiCache resources

# DynamoDB Table
resource "aws_dynamodb_table" "main" {
  name           = "${var.project_name}-${var.environment}-telemetry"
  billing_mode   = var.dynamodb_billing_mode
  read_capacity  = var.dynamodb_read_capacity
  write_capacity = var.dynamodb_write_capacity
  hash_key       = "device_id"
  range_key      = "timestamp"

  attribute {
    name = "device_id"
    type = "S"
  }

  attribute {
    name = "timestamp"
    type = "S"
  }

  attribute {
    name = "sound_type"
    type = "S"
  }

  global_secondary_index {
    name     = "sound-type-index"
    hash_key = "sound_type"
    range_key = "timestamp"
    read_capacity  = var.dynamodb_read_capacity
    write_capacity = var.dynamodb_write_capacity
  }

  server_side_encryption {
    enabled     = true
    kms_key_id  = var.kms_key_id
  }

  point_in_time_recovery {
    enabled = true
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-telemetry"
  })
}

# RDS Subnet Group
resource "aws_db_subnet_group" "main" {
  name       = "${var.project_name}-${var.environment}-db-subnet-group"
  subnet_ids = var.database_subnet_ids

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-db-subnet-group"
  })
}

# RDS Security Group
resource "aws_security_group" "rds" {
  name_prefix = "${var.project_name}-${var.environment}-rds-"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-rds-sg"
  })
}

# RDS Instance
resource "aws_db_instance" "main" {
  identifier = "${var.project_name}-${var.environment}-db"

  engine         = "postgres"
  engine_version = "15.4"
  instance_class = var.rds_instance_class

  allocated_storage     = var.rds_allocated_storage
  max_allocated_storage = var.rds_max_allocated_storage
  storage_type          = "gp3"
  storage_encrypted     = true
  kms_key_id           = var.kms_key_id

  db_name  = "iotsoundanalytics"
  username = "postgres"
  password = random_password.db_password.result

  vpc_security_group_ids = [aws_security_group.rds.id]
  db_subnet_group_name   = aws_db_subnet_group.main.name

  backup_retention_period = var.rds_backup_retention_period
  backup_window          = var.rds_backup_window
  maintenance_window     = var.rds_maintenance_window

  skip_final_snapshot = true
  deletion_protection = false

  performance_insights_enabled = true
  monitoring_interval         = 60
  monitoring_role_arn        = aws_iam_role.rds_enhanced_monitoring.arn

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-db"
  })
}

# Random password for RDS
resource "random_password" "db_password" {
  length  = 16
  special = true
}

# RDS Enhanced Monitoring Role
resource "aws_iam_role" "rds_enhanced_monitoring" {
  name = "${var.project_name}-${var.environment}-rds-enhanced-monitoring"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "monitoring.rds.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "rds_enhanced_monitoring" {
  role       = aws_iam_role.rds_enhanced_monitoring.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

# S3 Bucket
resource "aws_s3_bucket" "main" {
  bucket = "${var.project_name}-${var.environment}-data-${random_string.bucket_suffix.result}"

  tags = var.tags
}

resource "random_string" "bucket_suffix" {
  length  = 8
  special = false
  upper   = false
}

resource "aws_s3_bucket_versioning" "main" {
  bucket = aws_s3_bucket.main.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "main" {
  bucket = aws_s3_bucket.main.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = var.kms_key_id
      sse_algorithm     = "aws:kms"
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "main" {
  bucket = aws_s3_bucket.main.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "main" {
  count  = var.s3_lifecycle_enabled ? 1 : 0
  bucket = aws_s3_bucket.main.id

  rule {
    id     = "data_lifecycle"
    status = "Enabled"

    transition {
      days          = var.s3_transition_to_ia_days
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = var.s3_transition_to_glacier_days
      storage_class = "GLACIER"
    }

    expiration {
      days = 2555 # 7 years
    }
  }
}

# ElastiCache Subnet Group
resource "aws_elasticache_subnet_group" "main" {
  name       = "${var.project_name}-${var.environment}-cache-subnet-group"
  subnet_ids = var.private_subnet_ids

  tags = var.tags
}

# ElastiCache Security Group
resource "aws_security_group" "elasticache" {
  name_prefix = "${var.project_name}-${var.environment}-elasticache-"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 6379
    to_port     = 6379
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-elasticache-sg"
  })
}

# ElastiCache Cluster
resource "aws_elasticache_replication_group" "main" {
  replication_group_id       = "${var.project_name}-${var.environment}-cache"
  description                = "Redis cluster for ${var.project_name}-${var.environment}"

  node_type                  = var.elasticache_node_type
  port                       = 6379
  parameter_group_name       = "default.redis7"
  num_cache_clusters         = var.elasticache_num_cache_nodes

  subnet_group_name          = aws_elasticache_subnet_group.main.name
  security_group_ids         = [aws_security_group.elasticache.id]

  at_rest_encryption_enabled = true
  transit_encryption_enabled = true

  tags = var.tags
}

# Data source for VPC CIDR
data "aws_vpc" "main" {
  id = var.vpc_id
}
