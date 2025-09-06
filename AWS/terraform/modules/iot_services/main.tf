# IoT Services Module - Main Configuration
# This module creates IoT Core, Kinesis, and SQS services

# IoT Core
resource "aws_iot_thing_type" "main" {
  name = var.iot_thing_type_name

  tags = var.tags
}

resource "aws_iot_policy" "main" {
  name = var.iot_policy_name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "iot:Connect"
        ]
        Resource = "arn:aws:iot:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:client/*"
      },
      {
        Effect = "Allow"
        Action = [
          "iot:Publish"
        ]
        Resource = "arn:aws:iot:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:topic/*"
      },
      {
        Effect = "Allow"
        Action = [
          "iot:Subscribe"
        ]
        Resource = "arn:aws:iot:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:topicfilter/*"
      },
      {
        Effect = "Allow"
        Action = [
          "iot:Receive"
        ]
        Resource = "arn:aws:iot:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:topic/*"
      }
    ]
  })
}

# IoT Core Endpoint
data "aws_iot_endpoint" "main" {}

# Kinesis Data Stream
resource "aws_kinesis_stream" "main" {
  name             = "${var.project_name}-${var.environment}-audio-stream"
  shard_count      = var.kinesis_shard_count
  retention_period = var.kinesis_retention_hours

  shard_level_metrics = [
    "IncomingRecords",
    "OutgoingRecords",
  ]

  encryption_type = "KMS"
  kms_key_id      = "alias/aws/kinesis"

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-audio-stream"
  })
}

# SQS Queues
resource "aws_sqs_queue" "main" {
  name                       = "${var.project_name}-${var.environment}-main-queue"
  visibility_timeout_seconds = var.sqs_visibility_timeout_seconds
  message_retention_seconds  = var.sqs_message_retention_seconds
  delay_seconds              = 0
  max_message_size           = 262144
  receive_wait_time_seconds  = 0

  tags = var.tags
}

resource "aws_sqs_queue" "dlq" {
  name                       = "${var.project_name}-${var.environment}-dlq"
  visibility_timeout_seconds = var.sqs_visibility_timeout_seconds
  message_retention_seconds  = 1209600 # 14 days
  delay_seconds              = 0
  max_message_size           = 262144
  receive_wait_time_seconds  = 0

  tags = var.tags
}

resource "aws_sqs_queue" "alerts" {
  name                       = "${var.project_name}-${var.environment}-alerts-queue"
  visibility_timeout_seconds = var.sqs_visibility_timeout_seconds
  message_retention_seconds  = var.sqs_message_retention_seconds
  delay_seconds              = 0
  max_message_size           = 262144
  receive_wait_time_seconds  = 0

  tags = var.tags
}

# SQS Queue Policies
resource "aws_sqs_queue_policy" "main" {
  queue_url = aws_sqs_queue.main.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = [
          "sqs:SendMessage",
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes"
        ]
        Resource = aws_sqs_queue.main.arn
      }
    ]
  })
}

resource "aws_sqs_queue_policy" "alerts" {
  queue_url = aws_sqs_queue.alerts.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = [
          "sqs:SendMessage",
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes"
        ]
        Resource = aws_sqs_queue.alerts.arn
      }
    ]
  })
}

# IoT Rule to send data to Kinesis
resource "aws_iot_topic_rule" "kinesis" {
  name        = "${var.project_name}-${var.environment}-kinesis-rule"
  description = "Send IoT data to Kinesis"
  enabled     = true
  sql         = "SELECT * FROM 'device/+/data'"
  sql_version = "2016-03-23"

  kinesis {
    role_arn    = aws_iam_role.iot_kinesis.arn
    stream_name = aws_kinesis_stream.main.name
    partition_key = "device_id"
  }

  tags = var.tags
}

# IAM Role for IoT to Kinesis
resource "aws_iam_role" "iot_kinesis" {
  name = "${var.project_name}-${var.environment}-iot-kinesis-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "iot.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy" "iot_kinesis" {
  name = "${var.project_name}-${var.environment}-iot-kinesis-policy"
  role = aws_iam_role.iot_kinesis.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "kinesis:PutRecord"
        ]
        Resource = aws_kinesis_stream.main.arn
      }
    ]
  })
}

# EventBridge Rule for processing
resource "aws_cloudwatch_event_rule" "kinesis_processing" {
  name        = "${var.project_name}-${var.environment}-kinesis-processing-rule"
  description = "Trigger processing when data arrives in Kinesis"

  event_pattern = jsonencode({
    source      = ["aws.kinesis"]
    detail-type = ["Kinesis Data Stream Record"]
    detail = {
      streamName = [aws_kinesis_stream.main.name]
    }
  })

  tags = var.tags
}

# Data sources
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
