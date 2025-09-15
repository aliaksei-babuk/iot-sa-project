# Compute Module - Outputs

output "function_app_ids" {
  description = "Map of function app names to IDs"
  value = {
    audio_processing = azurerm_linux_function_app.audio_processing.id
    ml_inference     = azurerm_linux_function_app.ml_inference.id
    alert_processing = azurerm_linux_function_app.alert_processing.id
  }
}

output "function_app_names" {
  description = "Map of function app names"
  value = {
    audio_processing = azurerm_linux_function_app.audio_processing.name
    ml_inference     = azurerm_linux_function_app.ml_inference.name
    alert_processing = azurerm_linux_function_app.alert_processing.name
  }
}

output "function_app_hostnames" {
  description = "Map of function app hostnames"
  value = {
    audio_processing = azurerm_linux_function_app.audio_processing.default_hostname
    ml_inference     = azurerm_linux_function_app.ml_inference.default_hostname
    alert_processing = azurerm_linux_function_app.alert_processing.default_hostname
  }
}

output "function_app_identities" {
  description = "Map of function app identities"
  value = {
    audio_processing = azurerm_linux_function_app.audio_processing.identity
    ml_inference     = azurerm_linux_function_app.ml_inference.identity
    alert_processing = azurerm_linux_function_app.alert_processing.identity
  }
}

output "container_app_ids" {
  description = "Map of container app names to IDs"
  value = {
    ml_models  = var.log_analytics_workspace_id != "" ? azurerm_container_app.ml_models[0].id : null
    analytics  = var.log_analytics_workspace_id != "" ? azurerm_container_app.analytics[0].id : null
  }
}

output "container_app_names" {
  description = "Map of container app names"
  value = {
    ml_models  = var.log_analytics_workspace_id != "" ? azurerm_container_app.ml_models[0].name : null
    analytics  = var.log_analytics_workspace_id != "" ? azurerm_container_app.analytics[0].name : null
  }
}

output "container_app_environment_id" {
  description = "ID of the Container App Environment"
  value       = var.log_analytics_workspace_id != "" ? azurerm_container_app_environment.main[0].id : null
}

output "container_app_environment_name" {
  description = "Name of the Container App Environment"
  value       = var.log_analytics_workspace_id != "" ? azurerm_container_app_environment.main[0].name : null
}

output "logic_app_workflow_ids" {
  description = "Map of Logic App workflow names to IDs"
  value = {
    main   = azurerm_logic_app_workflow.main.id
    alerts = azurerm_logic_app_workflow.alerts.id
  }
}

output "logic_app_workflow_names" {
  description = "Map of Logic App workflow names"
  value = {
    main   = azurerm_logic_app_workflow.main.name
    alerts = azurerm_logic_app_workflow.alerts.name
  }
}

output "logic_app_workflow_identities" {
  description = "Map of Logic App workflow identities"
  value = {
    main   = azurerm_logic_app_workflow.main.identity
    alerts = azurerm_logic_app_workflow.alerts.identity
  }
}

output "storage_account_id" {
  description = "ID of the Function Apps storage account"
  value       = azurerm_storage_account.functions.id
}

output "storage_account_name" {
  description = "Name of the Function Apps storage account"
  value       = azurerm_storage_account.functions.name
}

output "storage_account_connection_string" {
  description = "Connection string of the Function Apps storage account"
  value       = azurerm_storage_account.functions.primary_connection_string
  sensitive   = true
}

output "service_plan_id" {
  description = "ID of the App Service Plan"
  value       = azurerm_service_plan.functions.id
}

output "service_plan_name" {
  description = "Name of the App Service Plan"
  value       = azurerm_service_plan.functions.name
}

output "eventgrid_system_topic_ids" {
  description = "Map of Event Grid system topic names to IDs"
  value = {
    functions  = azurerm_eventgrid_system_topic.functions.id
    containers = var.log_analytics_workspace_id != "" ? azurerm_eventgrid_system_topic.containers[0].id : null
  }
}

output "private_endpoint_ids" {
  description = "Map of private endpoint names to IDs"
  value = var.enable_private_endpoints ? {
    functions_storage = azurerm_private_endpoint.functions_storage[0].id
  } : {}
}
