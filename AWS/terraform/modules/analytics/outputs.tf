# Analytics Module - Outputs

output "sagemaker_notebook_instance_name" {
  description = "SageMaker notebook instance name"
  value       = aws_sagemaker_notebook_instance.main.name
}

output "sagemaker_model_name" {
  description = "SageMaker model name"
  value       = aws_sagemaker_model.main.name
}

output "sagemaker_endpoint_name" {
  description = "SageMaker endpoint name"
  value       = aws_sagemaker_endpoint.main.name
}

output "sagemaker_endpoint_arn" {
  description = "SageMaker endpoint ARN"
  value       = aws_sagemaker_endpoint.main.arn
}

output "sagemaker_endpoint_config_name" {
  description = "SageMaker endpoint configuration name"
  value       = aws_sagemaker_endpoint_configuration.main.name
}

output "kinesis_analytics_application_name" {
  description = "Kinesis Analytics application name"
  value       = aws_kinesis_analytics_application.main.name
}

output "kinesis_analytics_application_arn" {
  description = "Kinesis Analytics application ARN"
  value       = aws_kinesis_analytics_application.main.arn
}

output "kinesis_output_stream_name" {
  description = "Kinesis output stream name"
  value       = aws_kinesis_stream.output.name
}

output "kinesis_output_stream_arn" {
  description = "Kinesis output stream ARN"
  value       = aws_kinesis_stream.output.arn
}

output "quicksight_data_source_id" {
  description = "QuickSight data source ID"
  value       = aws_quicksight_data_source.main.data_source_id
}

output "quicksight_data_source_arn" {
  description = "QuickSight data source ARN"
  value       = aws_quicksight_data_source.main.arn
}

output "quicksight_dataset_id" {
  description = "QuickSight dataset ID"
  value       = aws_quicksight_data_set.main.data_set_id
}

output "quicksight_dataset_arn" {
  description = "QuickSight dataset ARN"
  value       = aws_quicksight_data_set.main.arn
}

output "quicksight_analysis_id" {
  description = "QuickSight analysis ID"
  value       = aws_quicksight_analysis.main.analysis_id
}

output "quicksight_analysis_arn" {
  description = "QuickSight analysis ARN"
  value       = aws_quicksight_analysis.main.arn
}

output "quicksight_dashboard_id" {
  description = "QuickSight dashboard ID"
  value       = aws_quicksight_dashboard.main.dashboard_id
}

output "quicksight_dashboard_arn" {
  description = "QuickSight dashboard ARN"
  value       = aws_quicksight_dashboard.main.arn
}

output "quicksight_dashboard_url" {
  description = "QuickSight dashboard URL"
  value       = "https://${data.aws_region.current.name}.quicksight.aws.amazon.com/sn/dashboards/${aws_quicksight_dashboard.main.dashboard_id}"
}
