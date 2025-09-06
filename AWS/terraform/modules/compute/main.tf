# Compute Module - Main Configuration
# This module creates Lambda functions, Fargate services, and Step Functions

# Lambda Function for Audio Processing
resource "aws_lambda_function" "audio_processing" {
  filename         = "audio_processing.zip"
  function_name    = "${var.project_name}-${var.environment}-audio-processing"
  role            = var.lambda_execution_role_arn
  handler         = "lambda_function.lambda_handler"
  source_code_hash = data.archive_file.audio_processing_zip.output_base64sha256
  runtime         = var.lambda_runtime
  timeout         = var.lambda_timeout
  memory_size     = var.lambda_memory_size

  vpc_config {
    subnet_ids         = var.private_subnet_ids
    security_group_ids = [aws_security_group.lambda.id]
  }

  environment {
    variables = {
      KINESIS_STREAM_NAME = var.kinesis_stream_arn
      DYNAMODB_TABLE     = var.dynamodb_table_arn
      S3_BUCKET          = var.s3_bucket_arn
    }
  }

  tags = var.tags
}

# Lambda Function for ML Inference
resource "aws_lambda_function" "ml_inference" {
  filename         = "ml_inference.zip"
  function_name    = "${var.project_name}-${var.environment}-ml-inference"
  role            = var.lambda_execution_role_arn
  handler         = "lambda_function.lambda_handler"
  source_code_hash = data.archive_file.ml_inference_zip.output_base64sha256
  runtime         = var.lambda_runtime
  timeout         = var.lambda_timeout
  memory_size     = var.lambda_memory_size

  vpc_config {
    subnet_ids         = var.private_subnet_ids
    security_group_ids = [aws_security_group.lambda.id]
  }

  environment {
    variables = {
      DYNAMODB_TABLE = var.dynamodb_table_arn
      SQS_QUEUE_URL  = var.sqs_queue_arn
    }
  }

  tags = var.tags
}

# Lambda Function for Alert Processing
resource "aws_lambda_function" "alert_processing" {
  filename         = "alert_processing.zip"
  function_name    = "${var.project_name}-${var.environment}-alert-processing"
  role            = var.lambda_execution_role_arn
  handler         = "lambda_function.lambda_handler"
  source_code_hash = data.archive_file.alert_processing_zip.output_base64sha256
  runtime         = var.lambda_runtime
  timeout         = var.lambda_timeout
  memory_size     = var.lambda_memory_size

  environment {
    variables = {
      SNS_TOPIC_ARN = var.sns_topic_arn
    }
  }

  tags = var.tags
}

# Lambda Layer for Dependencies
resource "aws_lambda_layer_version" "dependencies" {
  filename   = "dependencies.zip"
  layer_name = "${var.project_name}-${var.environment}-dependencies"

  compatible_runtimes = [var.lambda_runtime]

  tags = var.tags
}

# Archive files for Lambda functions
data "archive_file" "audio_processing_zip" {
  type        = "zip"
  output_path = "audio_processing.zip"
  source {
    content = <<EOF
import json
import boto3
import librosa
import numpy as np

def lambda_handler(event, context):
    # Audio processing logic
    return {
        'statusCode': 200,
        'body': json.dumps('Audio processed successfully')
    }
EOF
    filename = "lambda_function.py"
  }
}

data "archive_file" "ml_inference_zip" {
  type        = "zip"
  output_path = "ml_inference.zip"
  source {
    content = <<EOF
import json
import boto3

def lambda_handler(event, context):
    # ML inference logic
    return {
        'statusCode': 200,
        'body': json.dumps('ML inference completed')
    }
EOF
    filename = "lambda_function.py"
  }
}

data "archive_file" "alert_processing_zip" {
  type        = "zip"
  output_path = "alert_processing.zip"
  source {
    content = <<EOF
import json
import boto3

def lambda_handler(event, context):
    # Alert processing logic
    return {
        'statusCode': 200,
        'body': json.dumps('Alert processed successfully')
    }
EOF
    filename = "lambda_function.py"
  }
}

# ECS Cluster
resource "aws_ecs_cluster" "main" {
  name = "${var.project_name}-${var.environment}-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = var.tags
}

# ECS Task Definition
resource "aws_ecs_task_definition" "main" {
  family                   = "${var.project_name}-${var.environment}-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.fargate_cpu
  memory                   = var.fargate_memory
  execution_role_arn       = var.fargate_execution_role_arn

  container_definitions = jsonencode([
    {
      name  = "sound-analytics"
      image = "nginx:latest"
      
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.ecs.name
          "awslogs-region"        = data.aws_region.current.name
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])

  tags = var.tags
}

# ECS Service
resource "aws_ecs_service" "main" {
  name            = "${var.project_name}-${var.environment}-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.main.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [aws_security_group.ecs.id]
    assign_public_ip = false
  }

  depends_on = [aws_iam_role_policy_attachment.ecs_task_execution]

  tags = var.tags
}

# CloudWatch Log Group for ECS
resource "aws_cloudwatch_log_group" "ecs" {
  name              = "/ecs/${var.project_name}-${var.environment}"
  retention_in_days = 30

  tags = var.tags
}

# IAM Role for ECS Task Execution
resource "aws_iam_role_policy_attachment" "ecs_task_execution" {
  role       = var.fargate_execution_role_arn
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Step Functions State Machine
resource "aws_sfn_state_machine" "main" {
  name     = var.step_functions_state_machine_name
  role_arn = var.step_functions_execution_role_arn

  definition = jsonencode({
    Comment = "Sound Analytics Workflow"
    StartAt = "ProcessAudio"
    States = {
      ProcessAudio = {
        Type     = "Task"
        Resource = aws_lambda_function.audio_processing.arn
        Next     = "MLInference"
      }
      MLInference = {
        Type     = "Task"
        Resource = aws_lambda_function.ml_inference.arn
        Next     = "ProcessAlerts"
      }
      ProcessAlerts = {
        Type     = "Task"
        Resource = aws_lambda_function.alert_processing.arn
        End     = true
      }
    }
  })

  tags = var.tags
}

# Security Groups
resource "aws_security_group" "lambda" {
  name_prefix = "${var.project_name}-${var.environment}-lambda-"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-lambda-sg"
  })
}

resource "aws_security_group" "ecs" {
  name_prefix = "${var.project_name}-${var.environment}-ecs-"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
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
    Name = "${var.project_name}-${var.environment}-ecs-sg"
  })
}

# Data sources
data "aws_region" "current" {}
