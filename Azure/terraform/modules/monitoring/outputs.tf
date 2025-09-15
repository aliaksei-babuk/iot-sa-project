# Monitoring Module - Outputs

output "log_analytics_workspace_id" {
  description = "ID of the Log Analytics workspace"
  value       = azurerm_log_analytics_workspace.main.id
}

output "log_analytics_workspace_name" {
  description = "Name of the Log Analytics workspace"
  value       = azurerm_log_analytics_workspace.main.name
}

output "log_analytics_workspace_primary_shared_key" {
  description = "Primary shared key of the Log Analytics workspace"
  value       = azurerm_log_analytics_workspace.main.primary_shared_key
  sensitive   = true
}

output "log_analytics_workspace_secondary_shared_key" {
  description = "Secondary shared key of the Log Analytics workspace"
  value       = azurerm_log_analytics_workspace.main.secondary_shared_key
  sensitive   = true
}

output "log_analytics_workspace_workspace_id" {
  description = "Workspace ID of the Log Analytics workspace"
  value       = azurerm_log_analytics_workspace.main.workspace_id
}

output "application_insights_id" {
  description = "ID of the main Application Insights instance"
  value       = azurerm_application_insights.main.id
}

output "application_insights_name" {
  description = "Name of the main Application Insights instance"
  value       = azurerm_application_insights.main.name
}

output "application_insights_instrumentation_key" {
  description = "Instrumentation key of the main Application Insights instance"
  value       = azurerm_application_insights.main.instrumentation_key
  sensitive   = true
}

output "application_insights_connection_string" {
  description = "Connection string of the main Application Insights instance"
  value       = azurerm_application_insights.main.connection_string
  sensitive   = true
}

output "application_insights_app_id" {
  description = "App ID of the main Application Insights instance"
  value       = azurerm_application_insights.main.app_id
}

# Note: All services now use the single main Application Insights instance
# Use application_insights_id, application_insights_name, etc. for all services

output "action_group_id" {
  description = "ID of the action group"
  value       = azurerm_monitor_action_group.main.id
}

output "action_group_name" {
  description = "Name of the action group"
  value       = azurerm_monitor_action_group.main.name
}

output "metric_alert_ids" {
  description = "Map of metric alert names to IDs"
  value = merge(
    {
      for k, v in azurerm_monitor_metric_alert.function_availability : "function-${k}-availability" => v.id
    },
    {
      for k, v in azurerm_monitor_metric_alert.function_response_time : "function-${k}-response-time" => v.id
    },
    var.iot_hub_id != "" ? {
      "iot-hub-messages" = azurerm_monitor_metric_alert.iot_hub_messages[0].id
    } : {},
    var.cosmos_db_id != "" ? {
      "cosmos-db-ru" = azurerm_monitor_metric_alert.cosmos_db_ru[0].id
    } : {},
    var.sql_database_id != "" ? {
      "sql-db-dtu" = azurerm_monitor_metric_alert.sql_database_dtu[0].id
    } : {}
  )
}

output "log_alert_ids" {
  description = "Map of log alert names to IDs"
  value = merge(
    {
      for k, v in azurerm_monitor_scheduled_query_rules_alert.function_errors : "function-${k}-errors" => v.id
    },
    {
      "high-error-rate" = azurerm_monitor_scheduled_query_rules_alert.high_error_rate.id
      "security-events" = azurerm_monitor_scheduled_query_rules_alert.security_events.id
    }
  )
}

output "dashboard_id" {
  description = "ID of the monitoring dashboard"
  value       = var.enable_dashboard ? azurerm_dashboard.main[0].id : null
}

output "dashboard_name" {
  description = "Name of the monitoring dashboard"
  value       = var.enable_dashboard ? azurerm_dashboard.main[0].name : null
}
