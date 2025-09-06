# Azure IoT Sound Analytics - Outputs

output "resource_group_name" {
  description = "Name of the main resource group"
  value       = azurerm_resource_group.main.name
}

output "resource_group_location" {
  description = "Location of the main resource group"
  value       = azurerm_resource_group.main.location
}

# Networking outputs
output "vnet_id" {
  description = "ID of the virtual network"
  value       = module.networking.vnet_id
}

output "vnet_name" {
  description = "Name of the virtual network"
  value       = module.networking.vnet_name
}

output "subnet_ids" {
  description = "Map of subnet names to IDs"
  value       = module.networking.subnet_ids
}

# IoT Services outputs
output "iot_hub_id" {
  description = "ID of the IoT Hub"
  value       = module.iot_services.iot_hub_id
}

output "iot_hub_name" {
  description = "Name of the IoT Hub"
  value       = module.iot_services.iot_hub_name
}

output "iot_hub_hostname" {
  description = "Hostname of the IoT Hub"
  value       = module.iot_services.iot_hub_hostname
}

output "iot_hub_connection_string" {
  description = "Connection string for the IoT Hub"
  value       = module.iot_services.iot_hub_connection_string
  sensitive   = true
}

output "event_hub_namespace" {
  description = "Name of the Event Hub namespace"
  value       = module.iot_services.event_hub_namespace
}

output "event_hub_name" {
  description = "Name of the Event Hub"
  value       = module.iot_services.event_hub_name
}

output "event_hub_connection_string" {
  description = "Connection string for Event Hubs"
  value       = module.iot_services.event_hub_connection_string
  sensitive   = true
}

output "service_bus_connection_string" {
  description = "Connection string for Service Bus"
  value       = module.iot_services.service_bus_connection_string
  sensitive   = true
}

# Compute outputs
output "function_app_ids" {
  description = "Map of function app names to IDs"
  value       = module.compute.function_app_ids
}

output "function_app_names" {
  description = "Map of function app names"
  value       = module.compute.function_app_names
}

output "container_app_ids" {
  description = "Map of container app names to IDs"
  value       = module.compute.container_app_ids
}

output "container_app_names" {
  description = "Map of container app names"
  value       = module.compute.container_app_names
}

# Storage outputs
output "storage_account_id" {
  description = "ID of the storage account"
  value       = module.storage.storage_account_id
}

output "storage_account_name" {
  description = "Name of the storage account"
  value       = module.storage.storage_account_name
}

output "storage_account_key" {
  description = "Primary key of the storage account"
  value       = module.storage.storage_account_key
  sensitive   = true
}

output "cosmos_db_id" {
  description = "ID of the Cosmos DB account"
  value       = module.storage.cosmos_db_id
}

output "cosmos_db_endpoint" {
  description = "Endpoint of the Cosmos DB account"
  value       = module.storage.cosmos_db_endpoint
}

output "cosmos_db_key" {
  description = "Primary key of the Cosmos DB account"
  value       = module.storage.cosmos_db_key
  sensitive   = true
}

output "sql_server_id" {
  description = "ID of the SQL Server"
  value       = module.storage.sql_server_id
}

output "sql_server_fqdn" {
  description = "FQDN of the SQL Server"
  value       = module.storage.sql_server_fqdn
}

output "sql_database_id" {
  description = "ID of the SQL Database"
  value       = module.storage.sql_database_id
}

output "sql_database_name" {
  description = "Name of the SQL Database"
  value       = module.storage.sql_database_name
}

# Analytics outputs
output "stream_analytics_job_id" {
  description = "ID of the Stream Analytics job"
  value       = module.analytics.stream_analytics_job_id
}

output "ml_workspace_id" {
  description = "ID of the Machine Learning workspace"
  value       = module.analytics.ml_workspace_id
}

output "ml_workspace_name" {
  description = "Name of the Machine Learning workspace"
  value       = module.analytics.ml_workspace_name
}

# Security outputs
output "key_vault_id" {
  description = "ID of the Key Vault"
  value       = module.security.key_vault_id
}

output "key_vault_uri" {
  description = "URI of the Key Vault"
  value       = module.security.key_vault_uri
}

output "key_vault_name" {
  description = "Name of the Key Vault"
  value       = module.security.key_vault_name
}

# Monitoring outputs
output "log_analytics_workspace_id" {
  description = "ID of the Log Analytics workspace"
  value       = module.monitoring.log_analytics_workspace_id
}

output "application_insights_id" {
  description = "ID of the Application Insights instance"
  value       = module.monitoring.application_insights_id
}

output "application_insights_instrumentation_key" {
  description = "Instrumentation key for Application Insights"
  value       = module.monitoring.application_insights_instrumentation_key
  sensitive   = true
}

# API outputs
output "api_management_id" {
  description = "ID of the API Management instance"
  value       = module.api.api_management_id
}

output "api_management_name" {
  description = "Name of the API Management instance"
  value       = module.api.api_management_name
}

output "api_management_gateway_url" {
  description = "Gateway URL of the API Management instance"
  value       = module.api.api_management_gateway_url
}

output "front_door_id" {
  description = "ID of the Front Door instance"
  value       = module.api.front_door_id
}

output "front_door_hostname" {
  description = "Hostname of the Front Door instance"
  value       = module.api.front_door_hostname
}

# Summary outputs
output "deployment_summary" {
  description = "Summary of the deployment"
  value = {
    environment           = var.environment
    location             = var.location
    resource_group_name  = azurerm_resource_group.main.name
    iot_hub_name         = module.iot_services.iot_hub_name
    storage_account_name = module.storage.storage_account_name
    cosmos_db_name       = module.storage.cosmos_db_name
    api_gateway_url      = module.api.api_management_gateway_url
    front_door_url       = module.api.front_door_hostname
  }
}

output "connection_strings" {
  description = "Connection strings for external access"
  value = {
    iot_hub_connection_string     = module.iot_services.iot_hub_connection_string
    event_hub_connection_string   = module.iot_services.event_hub_connection_string
    service_bus_connection_string = module.iot_services.service_bus_connection_string
    storage_account_key           = module.storage.storage_account_key
    cosmos_db_key                 = module.storage.cosmos_db_key
  }
  sensitive = true
}

output "monitoring_endpoints" {
  description = "Monitoring and observability endpoints"
  value = {
    log_analytics_workspace_id = module.monitoring.log_analytics_workspace_id
    application_insights_id    = module.monitoring.application_insights_id
    key_vault_uri              = module.security.key_vault_uri
  }
}
