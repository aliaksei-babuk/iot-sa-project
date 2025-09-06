# Compute Module - Outputs

output "lambda_function_arn" {
  description = "Main Lambda function ARN"
  value       = aws_lambda_function.audio_processing.arn
}

output "lambda_function_name" {
  description = "Main Lambda function name"
  value       = aws_lambda_function.audio_processing.function_name
}

output "lambda_audio_processing_arn" {
  description = "Audio processing Lambda function ARN"
  value       = aws_lambda_function.audio_processing.arn
}

output "lambda_ml_inference_arn" {
  description = "ML inference Lambda function ARN"
  value       = aws_lambda_function.ml_inference.arn
}

output "lambda_alert_processing_arn" {
  description = "Alert processing Lambda function ARN"
  value       = aws_lambda_function.alert_processing.arn
}

output "lambda_layer_arn" {
  description = "Lambda layer ARN"
  value       = aws_lambda_layer_version.dependencies.arn
}

output "ecs_cluster_id" {
  description = "ECS cluster ID"
  value       = aws_ecs_cluster.main.id
}

output "ecs_cluster_arn" {
  description = "ECS cluster ARN"
  value       = aws_ecs_cluster.main.arn
}

output "ecs_task_definition_arn" {
  description = "ECS task definition ARN"
  value       = aws_ecs_task_definition.main.arn
}

output "fargate_service_arn" {
  description = "Fargate service ARN"
  value       = aws_ecs_service.main.id
}

output "fargate_service_name" {
  description = "Fargate service name"
  value       = aws_ecs_service.main.name
}

output "step_functions_state_machine_arn" {
  description = "Step Functions state machine ARN"
  value       = aws_sfn_state_machine.main.arn
}

output "step_functions_state_machine_name" {
  description = "Step Functions state machine name"
  value       = aws_sfn_state_machine.main.name
}

output "lambda_security_group_id" {
  description = "Lambda security group ID"
  value       = aws_security_group.lambda.id
}

output "ecs_security_group_id" {
  description = "ECS security group ID"
  value       = aws_security_group.ecs.id
}

output "cloudwatch_log_group_name" {
  description = "CloudWatch log group name"
  value       = aws_cloudwatch_log_group.ecs.name
}
