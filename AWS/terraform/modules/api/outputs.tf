# API Module - Outputs

output "api_gateway_id" {
  description = "API Gateway ID"
  value       = aws_api_gateway_rest_api.main.id
}

output "api_gateway_arn" {
  description = "API Gateway ARN"
  value       = aws_api_gateway_rest_api.main.execution_arn
}

output "api_gateway_url" {
  description = "API Gateway URL"
  value       = "https://${aws_api_gateway_rest_api.main.id}.execute-api.${data.aws_region.current.name}.amazonaws.com/${var.api_gateway_stage_name}"
}

output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID"
  value       = aws_cloudfront_distribution.main.id
}

output "cloudfront_domain_name" {
  description = "CloudFront distribution domain name"
  value       = aws_cloudfront_distribution.main.domain_name
}

output "cloudfront_arn" {
  description = "CloudFront distribution ARN"
  value       = aws_cloudfront_distribution.main.arn
}

output "alb_dns_name" {
  description = "Application Load Balancer DNS name"
  value       = aws_lb.main.dns_name
}

output "alb_arn" {
  description = "Application Load Balancer ARN"
  value       = aws_lb.main.arn
}

output "alb_zone_id" {
  description = "Application Load Balancer zone ID"
  value       = aws_lb.main.zone_id
}

output "alb_target_group_arn" {
  description = "ALB target group ARN"
  value       = aws_lb_target_group.main.arn
}

output "alb_security_group_id" {
  description = "ALB security group ID"
  value       = aws_security_group.alb.id
}

output "acm_certificate_arn" {
  description = "ACM certificate ARN"
  value       = aws_acm_certificate.main.arn
}

# Data source for current region
data "aws_region" "current" {}
