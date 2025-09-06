# Analytics Module - Outputs

output "stream_analytics_job_id" {
  description = "ID of the Stream Analytics job"
  value       = azurerm_stream_analytics_job.main.id
}

output "stream_analytics_job_name" {
  description = "Name of the Stream Analytics job"
  value       = azurerm_stream_analytics_job.main.name
}

output "stream_analytics_job_identity" {
  description = "Identity of the Stream Analytics job"
  value       = azurerm_stream_analytics_job.main.identity
}

output "ml_workspace_id" {
  description = "ID of the Machine Learning workspace"
  value       = azurerm_machine_learning_workspace.main.id
}

output "ml_workspace_name" {
  description = "Name of the Machine Learning workspace"
  value       = azurerm_machine_learning_workspace.main.name
}

output "ml_workspace_identity" {
  description = "Identity of the Machine Learning workspace"
  value       = azurerm_machine_learning_workspace.main.identity
}

output "ml_compute_cluster_id" {
  description = "ID of the Machine Learning compute cluster"
  value       = azurerm_machine_learning_compute_cluster.main.id
}

output "ml_compute_cluster_name" {
  description = "Name of the Machine Learning compute cluster"
  value       = azurerm_machine_learning_compute_cluster.main.name
}

output "ml_compute_instance_id" {
  description = "ID of the Machine Learning compute instance"
  value       = azurerm_machine_learning_compute_instance.main.id
}

output "ml_compute_instance_name" {
  description = "Name of the Machine Learning compute instance"
  value       = azurerm_machine_learning_compute_instance.main.name
}

output "time_series_insights_environment_id" {
  description = "ID of the Time Series Insights environment"
  value       = azurerm_iot_time_series_insights_gen2_environment.main.id
}

output "time_series_insights_environment_name" {
  description = "Name of the Time Series Insights environment"
  value       = azurerm_iot_time_series_insights_gen2_environment.main.name
}

output "time_series_insights_event_source_id" {
  description = "ID of the Time Series Insights event source"
  value       = azurerm_iot_time_series_insights_event_source_eventhub.main.id
}

output "power_bi_embedded_id" {
  description = "ID of the Power BI Embedded capacity"
  value       = var.enable_power_bi ? azurerm_powerbi_embedded.main[0].id : null
}

output "power_bi_embedded_name" {
  description = "Name of the Power BI Embedded capacity"
  value       = var.enable_power_bi ? azurerm_powerbi_embedded.main[0].name : null
}

output "data_factory_id" {
  description = "ID of the Data Factory"
  value       = azurerm_data_factory.main.id
}

output "data_factory_name" {
  description = "Name of the Data Factory"
  value       = azurerm_data_factory.main.name
}

output "data_factory_identity" {
  description = "Identity of the Data Factory"
  value       = azurerm_data_factory.main.identity
}

output "data_factory_pipeline_id" {
  description = "ID of the Data Factory pipeline"
  value       = azurerm_data_factory_pipeline.data_processing.id
}

output "data_factory_pipeline_name" {
  description = "Name of the Data Factory pipeline"
  value       = azurerm_data_factory_pipeline.data_processing.name
}

output "synapse_workspace_id" {
  description = "ID of the Synapse workspace"
  value       = var.enable_synapse ? azurerm_synapse_workspace.main[0].id : null
}

output "synapse_workspace_name" {
  description = "Name of the Synapse workspace"
  value       = var.enable_synapse ? azurerm_synapse_workspace.main[0].name : null
}

output "synapse_sql_pool_id" {
  description = "ID of the Synapse SQL pool"
  value       = var.enable_synapse ? azurerm_synapse_sql_pool.main[0].id : null
}

output "synapse_sql_pool_name" {
  description = "Name of the Synapse SQL pool"
  value       = var.enable_synapse ? azurerm_synapse_sql_pool.main[0].name : null
}

output "synapse_spark_pool_id" {
  description = "ID of the Synapse Spark pool"
  value       = var.enable_synapse ? azurerm_synapse_spark_pool.main[0].id : null
}

output "synapse_spark_pool_name" {
  description = "Name of the Synapse Spark pool"
  value       = var.enable_synapse ? azurerm_synapse_spark_pool.main[0].name : null
}
