# IoT Services Module - Outputs

output "iot_core_endpoint" {
  description = "IoT Core endpoint"
  value       = data.aws_iot_endpoint.main.endpoint_address
}

output "iot_core_arn" {
  description = "IoT Core ARN"
  value       = "arn:aws:iot:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:*"
}

output "iot_thing_type_name" {
  description = "Name of the IoT thing type"
  value       = aws_iot_thing_type.main.name
}

output "iot_policy_name" {
  description = "Name of the IoT policy"
  value       = aws_iot_policy.main.name
}

output "kinesis_stream_arn" {
  description = "Kinesis Data Stream ARN"
  value       = aws_kinesis_stream.main.arn
}

output "kinesis_stream_name" {
  description = "Kinesis Data Stream name"
  value       = aws_kinesis_stream.main.name
}

output "kinesis_stream_shard_count" {
  description = "Number of Kinesis shards"
  value       = aws_kinesis_stream.main.shard_count
}

output "sqs_queue_arn" {
  description = "Main SQS queue ARN"
  value       = aws_sqs_queue.main.arn
}

output "sqs_queue_url" {
  description = "Main SQS queue URL"
  value       = aws_sqs_queue.main.id
}

output "sqs_dlq_arn" {
  description = "Dead letter queue ARN"
  value       = aws_sqs_queue.dlq.arn
}

output "sqs_dlq_url" {
  description = "Dead letter queue URL"
  value       = aws_sqs_queue.dlq.id
}

output "sqs_alerts_arn" {
  description = "Alerts queue ARN"
  value       = aws_sqs_queue.alerts.arn
}

output "sqs_alerts_url" {
  description = "Alerts queue URL"
  value       = aws_sqs_queue.alerts.id
}

output "iot_rule_arn" {
  description = "IoT rule ARN"
  value       = aws_iot_topic_rule.kinesis.arn
}

output "eventbridge_rule_arn" {
  description = "EventBridge rule ARN"
  value       = aws_cloudwatch_event_rule.kinesis_processing.arn
}
