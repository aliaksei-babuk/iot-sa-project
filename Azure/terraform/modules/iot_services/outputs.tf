# IoT Services Module - Outputs

output "iot_hub_id" {
  description = "ID of the IoT Hub"
  value       = azurerm_iothub.main.id
}

output "iot_hub_name" {
  description = "Name of the IoT Hub"
  value       = azurerm_iothub.main.name
}

output "iot_hub_hostname" {
  description = "Hostname of the IoT Hub"
  value       = azurerm_iothub.main.hostname
}

output "iot_hub_connection_string" {
  description = "Connection string for the IoT Hub"
  value       = "HostName=${azurerm_iothub.main.hostname};SharedAccessKeyName=${azurerm_iothub.main.shared_access_policy[0].key_name};SharedAccessKey=${azurerm_iothub.main.shared_access_policy[0].primary_key}"
  sensitive   = true
}

output "iot_hub_primary_key" {
  description = "Primary key of the IoT Hub"
  value       = azurerm_iothub.main.shared_access_policy[0].primary_key
  sensitive   = true
}

output "iot_hub_secondary_key" {
  description = "Secondary key of the IoT Hub"
  value       = azurerm_iothub.main.shared_access_policy[0].secondary_key
  sensitive   = true
}

output "iot_hub_identity" {
  description = "Identity of the IoT Hub"
  value       = azurerm_iothub.main.identity
}

output "event_hub_namespace" {
  description = "Name of the Event Hub namespace"
  value       = azurerm_eventhub_namespace.main.name
}

output "event_hub_namespace_id" {
  description = "ID of the Event Hub namespace"
  value       = azurerm_eventhub_namespace.main.id
}

output "event_hub_name" {
  description = "Name of the Event Hub"
  value       = azurerm_eventhub.main.name
}

output "event_hub_id" {
  description = "ID of the Event Hub"
  value       = azurerm_eventhub.main.id
}

output "event_hub_connection_string" {
  description = "Connection string for Event Hubs"
  value       = azurerm_eventhub_authorization_rule.main.primary_connection_string
  sensitive   = true
}

output "event_hub_primary_key" {
  description = "Primary key for Event Hubs"
  value       = azurerm_eventhub_authorization_rule.main.primary_key
  sensitive   = true
}

output "event_hub_secondary_key" {
  description = "Secondary key for Event Hubs"
  value       = azurerm_eventhub_authorization_rule.main.secondary_key
  sensitive   = true
}

output "event_hub_identity" {
  description = "Identity of the Event Hub namespace"
  value       = azurerm_eventhub_namespace.main.identity
}

output "service_bus_namespace" {
  description = "Name of the Service Bus namespace"
  value       = azurerm_servicebus_namespace.main.name
}

output "service_bus_namespace_id" {
  description = "ID of the Service Bus namespace"
  value       = azurerm_servicebus_namespace.main.id
}

output "service_bus_connection_string" {
  description = "Connection string for Service Bus"
  value       = azurerm_servicebus_namespace_authorization_rule.main.primary_connection_string
  sensitive   = true
}

output "service_bus_primary_key" {
  description = "Primary key for Service Bus"
  value       = azurerm_servicebus_namespace_authorization_rule.main.primary_key
  sensitive   = true
}

output "service_bus_secondary_key" {
  description = "Secondary key for Service Bus"
  value       = azurerm_servicebus_namespace_authorization_rule.main.secondary_key
  sensitive   = true
}

output "service_bus_identity" {
  description = "Identity of the Service Bus namespace"
  value       = azurerm_servicebus_namespace.main.identity
}

output "service_bus_queue_ids" {
  description = "Map of Service Bus queue names to IDs"
  value = {
    alerts   = azurerm_servicebus_queue.alerts.id
    commands = azurerm_servicebus_queue.commands.id
  }
}

output "service_bus_topic_id" {
  description = "ID of the Service Bus topic"
  value       = azurerm_servicebus_topic.notifications.id
}

output "service_bus_subscription_ids" {
  description = "Map of Service Bus subscription names to IDs"
  value = {
    email = azurerm_servicebus_subscription.email.id
    sms   = azurerm_servicebus_subscription.sms.id
  }
}

output "storage_account_id" {
  description = "ID of the IoT Hub storage account"
  value       = azurerm_storage_account.iot_hub.id
}

output "storage_account_name" {
  description = "Name of the IoT Hub storage account"
  value       = azurerm_storage_account.iot_hub.name
}

output "storage_account_connection_string" {
  description = "Connection string of the IoT Hub storage account"
  value       = azurerm_storage_account.iot_hub.primary_connection_string
  sensitive   = true
}

output "private_endpoint_ids" {
  description = "Map of private endpoint names to IDs"
  value = var.enable_private_endpoints ? {
    iot_hub     = azurerm_private_endpoint.iot_hub[0].id
    eventhub    = azurerm_private_endpoint.eventhub[0].id
    servicebus  = azurerm_private_endpoint.servicebus[0].id
  } : {}
}
