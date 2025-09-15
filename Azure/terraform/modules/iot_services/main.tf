# IoT Services Module - Main Configuration

# IoT Hub
resource "azurerm_iothub" "main" {
  name                = "${var.project_name}-${var.environment}-iothub-${var.suffix}"
  resource_group_name = var.resource_group_name
  location            = var.location

  sku {
    name     = var.iot_hub_sku
    capacity = var.iot_hub_capacity
  }

  endpoint {
    type                       = "AzureIotHub.StorageContainer"
    connection_string          = azurerm_storage_account.iot_hub.primary_connection_string
    name                       = "storage"
    batch_frequency_in_seconds = 60
    max_chunk_size_in_bytes    = 10485760
    container_name             = azurerm_storage_container.iot_hub.name
    encoding                   = "Avro"
    file_name_format           = "{iothub}/{partition}/{YYYY}/{MM}/{DD}/{HH}/{mm}"
  }

  endpoint {
    type              = "AzureIotHub.EventHub"
    connection_string = azurerm_eventhub_authorization_rule.iot_hub.primary_connection_string
    name              = "events"
  }

  route {
    name           = "storage"
    source         = "DeviceMessages"
    condition      = "true"
    endpoint_names = ["storage"]
    enabled        = true
  }

  route {
    name           = "events"
    source         = "DeviceMessages"
    condition      = "true"
    endpoint_names = ["events"]
    enabled        = true
  }

  enrichment {
    key            = "tenant"
    value          = var.environment
    endpoint_names = ["events"]
  }

  enrichment {
    key            = "deviceLocation"
    value          = "$twin.tags.location"
    endpoint_names = ["events"]
  }

  cloud_to_device {
    max_delivery_count = 10
    default_ttl        = "PT1H"
    feedback {
      lock_duration = "PT5M"
      max_delivery_count = 10
    }
  }

  identity {
    type = "SystemAssigned"
  }
}

# IoT Hub Consumer Group
resource "azurerm_iothub_consumer_group" "main" {
  name                   = "sound-analytics"
  iothub_name            = azurerm_iothub.main.name
  resource_group_name    = var.resource_group_name
  eventhub_endpoint_name = "events"
}

# Storage Account for IoT Hub
resource "azurerm_storage_account" "iot_hub" {
  name                     = "${substr(replace(var.project_name, "-", ""), 0, 6)}${var.environment}iot${substr(replace(var.suffix, "-", ""), 0, 6)}"
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_container" "iot_hub" {
  name                  = "iothub"
  storage_account_name  = azurerm_storage_account.iot_hub.name
  container_access_type = "private"
}

# Event Hub Namespace
resource "azurerm_eventhub_namespace" "main" {
  name                = "${var.project_name}-${var.environment}-eventhub-ns-${var.suffix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "Standard"
  capacity            = 1

  identity {
    type = "SystemAssigned"
  }
}

# Event Hub
resource "azurerm_eventhub" "main" {
  name                = "${var.project_name}-${var.environment}-eventhub-${var.suffix}"
  namespace_name      = azurerm_eventhub_namespace.main.name
  resource_group_name = var.resource_group_name
  partition_count     = 4
  message_retention   = 1
}

# Event Hub Authorization Rule
resource "azurerm_eventhub_authorization_rule" "main" {
  name                = "sound-analytics"
  namespace_name      = azurerm_eventhub_namespace.main.name
  eventhub_name       = azurerm_eventhub.main.name
  resource_group_name = var.resource_group_name
  listen              = true
  send                = true
  manage              = false
}

# Event Hub Authorization Rule for IoT Hub
resource "azurerm_eventhub_authorization_rule" "iot_hub" {
  name                = "iothub"
  namespace_name      = azurerm_eventhub_namespace.main.name
  eventhub_name       = azurerm_eventhub.main.name
  resource_group_name = var.resource_group_name
  listen              = true
  send                = true
  manage              = false
}

# Service Bus Namespace
resource "azurerm_servicebus_namespace" "main" {
  name                = "${var.project_name}-${var.environment}-servicebus-ns-${var.suffix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "Standard"

  identity {
    type = "SystemAssigned"
  }
}

# Service Bus Queue for Alerts
resource "azurerm_servicebus_queue" "alerts" {
  name         = "alerts"
  namespace_id = azurerm_servicebus_namespace.main.id

  enable_partitioning = false
  max_size_in_megabytes = 1024
  default_message_ttl = "PT1H"
  enable_express = false
  enable_batched_operations = true
  dead_lettering_on_message_expiration = true
  max_delivery_count = 10
}

# Service Bus Queue for Commands
resource "azurerm_servicebus_queue" "commands" {
  name         = "commands"
  namespace_id = azurerm_servicebus_namespace.main.id

  enable_partitioning = false
  max_size_in_megabytes = 1024
  default_message_ttl = "PT1H"
  enable_express = false
  enable_batched_operations = true
  dead_lettering_on_message_expiration = true
  max_delivery_count = 10
}

# Service Bus Topic for Notifications
resource "azurerm_servicebus_topic" "notifications" {
  name         = "notifications"
  namespace_id = azurerm_servicebus_namespace.main.id

  enable_partitioning = false
  max_size_in_megabytes = 1024
  default_message_ttl = "PT1H"
  enable_express = false
  enable_batched_operations = true
  status = "Active"
}

# Service Bus Subscription for Email Notifications
resource "azurerm_servicebus_subscription" "email" {
  name     = "email"
  topic_id = azurerm_servicebus_topic.notifications.id

  max_delivery_count = 10
  dead_lettering_on_filter_evaluation_error = true
  dead_lettering_on_message_expiration = true
  default_message_ttl = "PT1H"
  enable_batched_operations = true
}

# Service Bus Subscription for SMS Notifications
resource "azurerm_servicebus_subscription" "sms" {
  name     = "sms"
  topic_id = azurerm_servicebus_topic.notifications.id

  max_delivery_count = 10
  dead_lettering_on_filter_evaluation_error = true
  dead_lettering_on_message_expiration = true
  default_message_ttl = "PT1H"
  enable_batched_operations = true
}

# Service Bus Authorization Rule
resource "azurerm_servicebus_namespace_authorization_rule" "main" {
  name         = "sound-analytics"
  namespace_id = azurerm_servicebus_namespace.main.id
  listen       = true
  send         = true
  manage       = false
}

# Private Endpoints (if enabled)
resource "azurerm_private_endpoint" "iot_hub" {
  count               = var.enable_private_endpoints ? 1 : 0
  name                = "${var.project_name}-${var.environment}-iothub-pe-${var.suffix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.subnet_ids["private-integration"]

  private_service_connection {
    name                           = "iothub-connection"
    private_connection_resource_id = azurerm_iothub.main.id
    subresource_names              = ["iotHub"]
    is_manual_connection           = false
  }
}

resource "azurerm_private_endpoint" "eventhub" {
  count               = var.enable_private_endpoints ? 1 : 0
  name                = "${var.project_name}-${var.environment}-eventhub-pe-${var.suffix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.subnet_ids["private-integration"]

  private_service_connection {
    name                           = "eventhub-connection"
    private_connection_resource_id = azurerm_eventhub_namespace.main.id
    subresource_names              = ["namespace"]
    is_manual_connection           = false
  }
}

resource "azurerm_private_endpoint" "servicebus" {
  count               = var.enable_private_endpoints ? 1 : 0
  name                = "${var.project_name}-${var.environment}-servicebus-pe-${var.suffix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.subnet_ids["private-integration"]

  private_service_connection {
    name                           = "servicebus-connection"
    private_connection_resource_id = azurerm_servicebus_namespace.main.id
    subresource_names              = ["namespace"]
    is_manual_connection           = false
  }
}

# Private DNS Records (if private endpoints enabled)
resource "azurerm_private_dns_a_record" "iot_hub" {
  count               = var.enable_private_endpoints && contains(keys(var.private_dns_zone_names), "servicebus") ? 1 : 0
  name                = azurerm_iothub.main.name
  zone_name           = var.private_dns_zone_names["servicebus"]
  resource_group_name = var.resource_group_name
  ttl                 = 300
  records             = [azurerm_private_endpoint.iot_hub[0].private_service_connection[0].private_ip_address]
}

resource "azurerm_private_dns_a_record" "eventhub" {
  count               = var.enable_private_endpoints && contains(keys(var.private_dns_zone_names), "servicebus") ? 1 : 0
  name                = azurerm_eventhub_namespace.main.name
  zone_name           = var.private_dns_zone_names["servicebus"]
  resource_group_name = var.resource_group_name
  ttl                 = 300
  records             = [azurerm_private_endpoint.eventhub[0].private_service_connection[0].private_ip_address]
}

resource "azurerm_private_dns_a_record" "servicebus" {
  count               = var.enable_private_endpoints && contains(keys(var.private_dns_zone_names), "servicebus") ? 1 : 0
  name                = azurerm_servicebus_namespace.main.name
  zone_name           = var.private_dns_zone_names["servicebus"]
  resource_group_name = var.resource_group_name
  ttl                 = 300
  records             = [azurerm_private_endpoint.servicebus[0].private_service_connection[0].private_ip_address]
}
