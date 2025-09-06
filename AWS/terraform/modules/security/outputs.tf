# Security Module - Outputs

output "kms_key_id" {
  description = "ID of the KMS key"
  value       = aws_kms_key.main.key_id
}

output "kms_key_arn" {
  description = "ARN of the KMS key"
  value       = aws_kms_key.main.arn
}

output "kms_alias_name" {
  description = "Name of the KMS alias"
  value       = aws_kms_alias.main.name
}

output "lambda_execution_role_arn" {
  description = "ARN of the Lambda execution role"
  value       = aws_iam_role.lambda_execution.arn
}

output "fargate_execution_role_arn" {
  description = "ARN of the Fargate execution role"
  value       = aws_iam_role.fargate_execution.arn
}

output "fargate_task_role_arn" {
  description = "ARN of the Fargate task role"
  value       = aws_iam_role.fargate_task.arn
}

output "step_functions_execution_role_arn" {
  description = "ARN of the Step Functions execution role"
  value       = aws_iam_role.step_functions_execution.arn
}

output "sagemaker_execution_role_arn" {
  description = "ARN of the SageMaker execution role"
  value       = aws_iam_role.sagemaker_execution.arn
}

output "quicksight_execution_role_arn" {
  description = "ARN of the QuickSight execution role"
  value       = aws_iam_role.quicksight_execution.arn
}

output "api_gateway_execution_role_arn" {
  description = "ARN of the API Gateway execution role"
  value       = aws_iam_role.api_gateway_execution.arn
}

output "admin_group_name" {
  description = "Name of the admin group"
  value       = aws_iam_group.admin.name
}

output "waf_web_acl_arn" {
  description = "ARN of the WAF Web ACL"
  value       = aws_wafv2_web_acl.main.arn
}

output "waf_web_acl_id" {
  description = "ID of the WAF Web ACL"
  value       = aws_wafv2_web_acl.main.id
}

output "security_hub_arn" {
  description = "ARN of the Security Hub"
  value       = aws_securityhub_account.main.arn
}

output "guardduty_detector_id" {
  description = "ID of the GuardDuty detector"
  value       = aws_guardduty_detector.main.id
}
