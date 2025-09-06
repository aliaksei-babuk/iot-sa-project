# Analytics Module - Main Configuration
# This module creates SageMaker, QuickSight, and Kinesis Analytics resources

# SageMaker Notebook Instance
resource "aws_sagemaker_notebook_instance" "main" {
  name          = "${var.project_name}-${var.environment}-notebook"
  role_arn      = var.sagemaker_execution_role_arn
  instance_type = var.sagemaker_instance_type

  tags = var.tags
}

# SageMaker Model
resource "aws_sagemaker_model" "main" {
  name               = "${var.project_name}-${var.environment}-model"
  execution_role_arn = var.sagemaker_execution_role_arn

  primary_container {
    image = "763104351884.dkr.ecr.${data.aws_region.current.name}.amazonaws.com/pytorch-inference:1.12-cpu-py38-ubuntu20.04-sagemaker"
    
    environment = {
      SAGEMAKER_PROGRAM = "sound_classification.py"
      SAGEMAKER_SUBMIT_DIRECTORY = "s3://${var.s3_bucket_name}/models/"
    }
  }

  tags = var.tags
}

# SageMaker Endpoint Configuration
resource "aws_sagemaker_endpoint_configuration" "main" {
  name = "${var.project_name}-${var.environment}-endpoint-config"

  production_variants {
    variant_name           = "primary"
    model_name            = aws_sagemaker_model.main.name
    initial_instance_count = var.sagemaker_instance_count
    instance_type         = var.sagemaker_instance_type
    initial_variant_weight = 100
  }

  tags = var.tags
}

# SageMaker Endpoint
resource "aws_sagemaker_endpoint" "main" {
  name                 = "${var.project_name}-${var.environment}-endpoint"
  endpoint_config_name = aws_sagemaker_endpoint_configuration.main.name

  tags = var.tags
}

# Kinesis Analytics Application
resource "aws_kinesis_analytics_application" "main" {
  name = var.kinesis_analytics_application_name

  inputs {
    name_prefix = "SOURCE_SQL_STREAM"

    kinesis_stream {
      resource_arn = var.kinesis_stream_arn
      role_arn     = aws_iam_role.kinesis_analytics.arn
    }

    schema {
      record_columns {
        name     = "device_id"
        sql_type = "VARCHAR(64)"
        mapping  = "$.device_id"
      }

      record_columns {
        name     = "timestamp"
        sql_type = "TIMESTAMP"
        mapping  = "$.timestamp"
      }

      record_columns {
        name     = "sound_type"
        sql_type = "VARCHAR(32)"
        mapping  = "$.sound_type"
      }

      record_columns {
        name     = "confidence"
        sql_type = "DOUBLE"
        mapping  = "$.confidence"
      }

      record_format {
        record_format_type = "JSON"
      }
    }
  }

  outputs {
    name = "DESTINATION_SQL_STREAM"

    kinesis_stream {
      resource_arn = aws_kinesis_stream.output.arn
      role_arn     = aws_iam_role.kinesis_analytics.arn
    }

    schema {
      record_format_type = "JSON"
    }
  }

  tags = var.tags
}

# Kinesis Stream for Analytics Output
resource "aws_kinesis_stream" "output" {
  name             = "${var.project_name}-${var.environment}-analytics-output"
  shard_count      = 1
  retention_period = 24

  shard_level_metrics = [
    "IncomingRecords",
    "OutgoingRecords",
  ]

  encryption_type = "KMS"
  kms_key_id      = "alias/aws/kinesis"

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-analytics-output"
  })
}

# IAM Role for Kinesis Analytics
resource "aws_iam_role" "kinesis_analytics" {
  name = "${var.project_name}-${var.environment}-kinesis-analytics-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "kinesisanalytics.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy" "kinesis_analytics" {
  name = "${var.project_name}-${var.environment}-kinesis-analytics-policy"
  role = aws_iam_role.kinesis_analytics.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "kinesis:DescribeStream",
          "kinesis:GetShardIterator",
          "kinesis:GetRecords",
          "kinesis:ListStreams"
        ]
        Resource = [
          var.kinesis_stream_arn,
          aws_kinesis_stream.output.arn
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "kinesis:PutRecord",
          "kinesis:PutRecords"
        ]
        Resource = aws_kinesis_stream.output.arn
      }
    ]
  })
}

# QuickSight Data Source
resource "aws_quicksight_data_source" "main" {
  data_source_id = "${var.project_name}-${var.environment}-datasource"
  name           = "${var.project_name}-${var.environment}-datasource"

  type = "S3"

  parameters {
    s3_parameters {
      manifest_file_location {
        bucket = var.s3_bucket_name
        key    = "quicksight/manifest.json"
      }
    }
  }

  tags = var.tags
}

# QuickSight Dataset
resource "aws_quicksight_data_set" "main" {
  data_set_id = "${var.project_name}-${var.environment}-dataset"
  name        = "${var.project_name}-${var.environment}-dataset"

  physical_table_map {
    physical_table_map_id = "main_table"
    s3_source {
      data_source_arn = aws_quicksight_data_source.main.arn
      input_columns {
        name = "device_id"
        type = "STRING"
      }
      input_columns {
        name = "timestamp"
        type = "DATETIME"
      }
      input_columns {
        name = "sound_type"
        type = "STRING"
      }
      input_columns {
        name = "confidence"
        type = "DECIMAL"
      }
    }
  }

  tags = var.tags
}

# QuickSight Analysis
resource "aws_quicksight_analysis" "main" {
  analysis_id = "${var.project_name}-${var.environment}-analysis"
  name        = "${var.project_name}-${var.environment}-analysis"

  definition {
    data_set_identifiers = [
      {
        data_set_arn = aws_quicksight_data_set.main.arn
        data_set_identifier = "main_dataset"
      }
    ]

    sheets {
      sheet_id = "main_sheet"
      title    = "Sound Analytics Dashboard"
    }
  }

  tags = var.tags
}

# QuickSight Dashboard
resource "aws_quicksight_dashboard" "main" {
  dashboard_id = "${var.project_name}-${var.environment}-dashboard"
  name         = "${var.project_name}-${var.environment}-dashboard"

  definition {
    data_set_identifiers = [
      {
        data_set_arn = aws_quicksight_data_set.main.arn
        data_set_identifier = "main_dataset"
      }
    ]

    sheets {
      sheet_id = "main_sheet"
      title    = "Sound Analytics Dashboard"
    }
  }

  tags = var.tags
}

# Data sources
data "aws_region" "current" {}
