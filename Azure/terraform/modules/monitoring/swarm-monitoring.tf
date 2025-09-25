# Swarm Monitoring Configuration - Мониторинг роя агентов

# Swarm Agent Health Dashboard
resource "azurerm_dashboard" "swarm_monitoring" {
  count               = var.enable_monitoring ? 1 : 0
  name                = "${var.project_name}-${var.environment}-swarm-dashboard-${var.suffix}"
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.common_tags

  dashboard_properties = jsonencode({
    lenses = {
      "0" = {
        order = 0
        parts = {
          "0" = {
            position = {
              x = 0
              y = 0
              rowSpan = 4
              colSpan = 6
            }
            metadata = {
              inputs = [
                {
                  name = "resourceId"
                  value = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/${var.resource_group_name}/providers/Microsoft.Devices/IotHubs/${var.project_name}-${var.environment}-iothub-${var.suffix}"
                }
              ]
              type = "Extension/Microsoft_OperationsManagementSuite_Workspace/PartType/LogsDashboardPart"
              settings = {
                content = {
                  Query = <<-EOT
                    // Swarm Agent Status
                    AzureDiagnostics
                    | where ResourceProvider == "MICROSOFT.DEVICES" and ResourceType == "IOTHUBS"
                    | where Category == "DeviceTelemetry"
                    | where json_extract(properties, '$.agentId') != ""
                    | extend agentId = json_extract(properties, '$.agentId')
                    | extend swarmId = json_extract(properties, '$.swarmId')
                    | extend timestamp = todatetime(json_extract(properties, '$.timestamp'))
                    | project timestamp, agentId, swarmId, properties
                    | order by timestamp desc
                    | take 100
                  EOT
                  title = "Swarm Agent Telemetry"
                  visualization = "table"
                }
              }
            }
          }
          "1" = {
            position = {
              x = 6
              y = 0
              rowSpan = 2
              colSpan = 6
            }
            metadata = {
              inputs = [
                {
                  name = "resourceId"
                  value = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/${var.resource_group_name}/providers/Microsoft.Devices/IotHubs/${var.project_name}-${var.environment}-iothub-${var.suffix}"
                }
              ]
              type = "Extension/Microsoft_OperationsManagementSuite_Workspace/PartType/LogsDashboardPart"
              settings = {
                content = {
                  Query = <<-EOT
                    // Active Agents Count
                    AzureDiagnostics
                    | where ResourceProvider == "MICROSOFT.DEVICES" and ResourceType == "IOTHUBS"
                    | where Category == "DeviceTelemetry"
                    | where json_extract(properties, '$.agentId') != ""
                    | extend agentId = json_extract(properties, '$.agentId')
                    | where timestamp > ago(5m)
                    | summarize count() by bin(timestamp, 1m)
                    | render timechart
                  EOT
                  title = "Active Agents Over Time"
                  visualization = "timechart"
                }
              }
            }
          }
          "2" = {
            position = {
              x = 6
              y = 2
              rowSpan = 2
              colSpan = 6
            }
            metadata = {
              inputs = [
                {
                  name = "resourceId"
                  value = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/${var.resource_group_name}/providers/Microsoft.Devices/IotHubs/${var.project_name}-${var.environment}-iothub-${var.suffix}"
                }
              ]
              type = "Extension/Microsoft_OperationsManagementSuite_Workspace/PartType/LogsDashboardPart"
              settings = {
                content = {
                  Query = <<-EOT
                    // Sound Classification Distribution
                    AzureDiagnostics
                    | where ResourceProvider == "MICROSOFT.DEVICES" and ResourceType == "IOTHUBS"
                    | where Category == "DeviceTelemetry"
                    | where json_extract(properties, '$.classification.sound_type') != ""
                    | extend soundType = json_extract(properties, '$.classification.sound_type')
                    | extend confidence = todouble(json_extract(properties, '$.classification.confidence'))
                    | where confidence > 0.7
                    | summarize count() by soundType
                    | render piechart
                  EOT
                  title = "Sound Classification Distribution"
                  visualization = "piechart"
                }
              }
            }
          }
        }
      }
    }
  })
}

# Swarm Agent Health Alerts
resource "azurerm_monitor_metric_alert" "swarm_agent_offline" {
  count               = var.enable_monitoring ? 1 : 0
  name                = "${var.project_name}-${var.environment}-swarm-agent-offline-${var.suffix}"
  resource_group_name = var.resource_group_name
  scopes              = [var.iot_hub_id]
  description         = "Alert when swarm agents go offline"
  severity            = 2
  frequency           = "PT1M"
  window_size         = "PT5M"
  enabled             = true

  criteria {
    metric_namespace = "Microsoft.Devices/IotHubs"
    metric_name      = "d2c.telemetry.ingress.allProtocol"
    aggregation      = "Count"
    operator         = "LessThan"
    threshold        = 1
  }

  action {
    action_group_id = azurerm_monitor_action_group.main.id
  }

  tags = var.common_tags
}

# Swarm Agent Error Rate Alert
resource "azurerm_monitor_metric_alert" "swarm_agent_errors" {
  count               = var.enable_monitoring ? 1 : 0
  name                = "${var.project_name}-${var.environment}-swarm-agent-errors-${var.suffix}"
  resource_group_name = var.resource_group_name
  scopes              = [var.iot_hub_id]
  description         = "Alert when swarm agent error rate is high"
  severity            = 1
  frequency           = "PT1M"
  window_size         = "PT5M"
  enabled             = true

  criteria {
    metric_namespace = "Microsoft.Devices/IotHubs"
    metric_name      = "d2c.telemetry.ingress.invalid"
    aggregation      = "Count"
    operator         = "GreaterThan"
    threshold        = 10
  }

  action {
    action_group_id = azurerm_monitor_action_group.main.id
  }

  tags = var.common_tags
}

# Swarm Agent Performance Alert
resource "azurerm_monitor_metric_alert" "swarm_agent_performance" {
  count               = var.enable_monitoring ? 1 : 0
  name                = "${var.project_name}-${var.environment}-swarm-agent-performance-${var.suffix}"
  resource_group_name = var.resource_group_name
  scopes              = [var.iot_hub_id]
  description         = "Alert when swarm agent performance degrades"
  severity            = 2
  frequency           = "PT5M"
  window_size         = "PT15M"
  enabled             = true

  criteria {
    metric_namespace = "Microsoft.Devices/IotHubs"
    metric_name      = "d2c.telemetry.ingress.success"
    aggregation      = "Count"
    operator         = "LessThan"
    threshold        = 50
  }

  action {
    action_group_id = azurerm_monitor_action_group.main.id
  }

  tags = var.common_tags
}

# Swarm Agent Log Analytics Query Pack
resource "azurerm_log_analytics_query_pack" "swarm_queries" {
  count               = var.enable_monitoring ? 1 : 0
  name                = "${var.project_name}-${var.environment}-swarm-queries-${var.suffix}"
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.common_tags
}

# Swarm Agent Queries
resource "azurerm_log_analytics_query" "swarm_agent_status" {
  count           = var.enable_monitoring ? 1 : 0
  name            = "swarm-agent-status"
  query_pack_id   = azurerm_log_analytics_query_pack.swarm_queries[0].id
  display_name    = "Swarm Agent Status"
  description     = "Current status of all swarm agents"
  body            = <<-EOT
    // Swarm Agent Status Query
    AzureDiagnostics
    | where ResourceProvider == "MICROSOFT.DEVICES" and ResourceType == "IOTHUBS"
    | where Category == "DeviceTelemetry"
    | where json_extract(properties, '$.agentId') != ""
    | extend agentId = json_extract(properties, '$.agentId')
    | extend swarmId = json_extract(properties, '$.swarmId')
    | extend timestamp = todatetime(json_extract(properties, '$.timestamp'))
    | extend status = json_extract(properties, '$.status')
    | project timestamp, agentId, swarmId, status
    | order by timestamp desc
    | take 100
  EOT
  tags = {
    "Category" = "Swarm Monitoring"
    "Type"     = "Agent Status"
  }
}

resource "azurerm_log_analytics_query" "swarm_agent_health" {
  count           = var.enable_monitoring ? 1 : 0
  name            = "swarm-agent-health"
  query_pack_id   = azurerm_log_analytics_query_pack.swarm_queries[0].id
  display_name    = "Swarm Agent Health Metrics"
  description     = "Health metrics for swarm agents"
  body            = <<-EOT
    // Swarm Agent Health Metrics
    AzureDiagnostics
    | where ResourceProvider == "MICROSOFT.DEVICES" and ResourceType == "IOTHUBS"
    | where Category == "DeviceTelemetry"
    | where json_extract(properties, '$.health') != ""
    | extend agentId = json_extract(properties, '$.agentId')
    | extend cpuUsage = todouble(json_extract(properties, '$.health.cpu_usage'))
    | extend memoryUsage = todouble(json_extract(properties, '$.health.memory_usage'))
    | extend diskUsage = todouble(json_extract(properties, '$.health.disk_usage'))
    | extend status = json_extract(properties, '$.health.status')
    | project timestamp, agentId, cpuUsage, memoryUsage, diskUsage, status
    | order by timestamp desc
    | take 100
  EOT
  tags = {
    "Category" = "Swarm Monitoring"
    "Type"     = "Health Metrics"
  }
}

resource "azurerm_log_analytics_query" "swarm_sound_classification" {
  count           = var.enable_monitoring ? 1 : 0
  name            = "swarm-sound-classification"
  query_pack_id   = azurerm_log_analytics_query_pack.swarm_queries[0].id
  display_name    = "Swarm Sound Classification"
  description     = "Sound classification results from swarm agents"
  body            = <<-EOT
    // Swarm Sound Classification
    AzureDiagnostics
    | where ResourceProvider == "MICROSOFT.DEVICES" and ResourceType == "IOTHUBS"
    | where Category == "DeviceTelemetry"
    | where json_extract(properties, '$.classification') != ""
    | extend agentId = json_extract(properties, '$.agentId')
    | extend soundType = json_extract(properties, '$.classification.sound_type')
    | extend confidence = todouble(json_extract(properties, '$.classification.confidence'))
    | extend droneDetected = json_extract(properties, '$.classification.drone_detected')
    | project timestamp, agentId, soundType, confidence, droneDetected
    | where confidence > 0.7
    | order by timestamp desc
    | take 100
  EOT
  tags = {
    "Category" = "Swarm Monitoring"
    "Type"     = "Sound Classification"
  }
}

# Swarm Agent Workbooks
resource "azurerm_application_insights_workbook" "swarm_dashboard" {
  count               = var.enable_monitoring ? 1 : 0
  name                = "${var.project_name}-${var.environment}-swarm-dashboard-${var.suffix}"
  resource_group_name = var.resource_group_name
  location            = var.location
  display_name        = "Swarm Agents Dashboard"
  source_id           = azurerm_application_insights.main.id
  category            = "swarm-monitoring"
  tags                = var.common_tags

  serialized_data = jsonencode({
    version = "Notebook/1.0"
    items = [
      {
        type = 1
        content = {
          json = "## Swarm Agents Overview\n\nThis dashboard provides real-time monitoring of your IoT sound analytics swarm agents."
        }
        name = "text - 0"
      },
      {
        type = 3
        content = {
          version = "KqlItem/1.0"
          query = "// Active Swarm Agents\nAzureDiagnostics\n| where ResourceProvider == \"MICROSOFT.DEVICES\" and ResourceType == \"IOTHUBS\"\n| where Category == \"DeviceTelemetry\"\n| where json_extract(properties, '$.agentId') != \"\"\n| extend agentId = json_extract(properties, '$.agentId')\n| where timestamp > ago(1h)\n| summarize count() by bin(timestamp, 5m)\n| render timechart"
          size = 0
          title = "Active Agents Over Time"
          queryType = 0
          resourceType = "microsoft.insights/components"
        }
        name = "query - 1"
      },
      {
        type = 3
        content = {
          version = "KqlItem/1.0"
          query = "// Sound Classification Results\nAzureDiagnostics\n| where ResourceProvider == \"MICROSOFT.DEVICES\" and ResourceType == \"IOTHUBS\"\n| where Category == \"DeviceTelemetry\"\n| where json_extract(properties, '$.classification.sound_type') != \"\"\n| extend soundType = json_extract(properties, '$.classification.sound_type')\n| extend confidence = todouble(json_extract(properties, '$.classification.confidence'))\n| where confidence > 0.7\n| summarize count() by soundType\n| render piechart"
          size = 0
          title = "Sound Classification Distribution"
          queryType = 0
          resourceType = "microsoft.insights/components"
        }
        name = "query - 2"
      }
    ]
  })
}


