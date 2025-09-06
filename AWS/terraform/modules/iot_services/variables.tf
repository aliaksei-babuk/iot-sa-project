# IoT Services Module - Variables

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

variable "iot_thing_type_name" {
  description = "Name of the IoT thing type"
  type        = string
}

variable "iot_policy_name" {
  description = "Name of the IoT policy"
  type        = string
}

variable "kinesis_shard_count" {
  description = "Number of Kinesis shards"
  type        = number
}

variable "kinesis_retention_hours" {
  description = "Kinesis data retention in hours"
  type        = number
}

variable "sqs_visibility_timeout_seconds" {
  description = "SQS visibility timeout in seconds"
  type        = number
}

variable "sqs_message_retention_seconds" {
  description = "SQS message retention in seconds"
  type        = number
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
