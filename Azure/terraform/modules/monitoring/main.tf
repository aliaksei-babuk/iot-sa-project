# Monitoring Module - Main Configuration

# Log Analytics Workspace
resource "azurerm_log_analytics_workspace" "main" {
  name                = "${var.project_name}-${var.environment}-logs-${var.suffix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "PerGB2018"
  retention_in_days   = var.retention_days
  tags                = var.common_tags
}

# Application Insights
resource "azurerm_application_insights" "main" {
  name                = "${var.project_name}-${var.environment}-appinsights-${var.suffix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  workspace_id        = azurerm_log_analytics_workspace.main.id
  application_type    = "web"
  tags                = var.common_tags

  daily_data_cap_in_gb                  = 100
  daily_data_cap_notifications_disabled = false
  retention_in_days                      = var.retention_days
  sampling_percentage                    = 100
  disable_ip_masking                     = false
}

# Note: Using single Application Insights instance for all services
# Function Apps and Container Apps will use the main Application Insights instance

# Action Group for Alerts
resource "azurerm_monitor_action_group" "main" {
  name                = "${var.project_name}-${var.environment}-alerts-${var.suffix}"
  resource_group_name = var.resource_group_name
  short_name          = "iot-alerts"
  tags                = var.common_tags

  dynamic "email_receiver" {
    for_each = var.admin_email != "" ? [1] : []
    content {
      name          = "admin"
      email_address = var.admin_email
    }
  }

  dynamic "email_receiver" {
    for_each = var.additional_email_receivers
    content {
      name          = email_receiver.value.name
      email_address = email_receiver.value.email
    }
  }

  dynamic "sms_receiver" {
    for_each = var.sms_receivers
    content {
      name         = sms_receiver.value.name
      country_code = sms_receiver.value.country_code
      phone_number = sms_receiver.value.phone_number
    }
  }

  dynamic "webhook_receiver" {
    for_each = var.webhook_receivers
    content {
      name        = webhook_receiver.value.name
      service_uri = webhook_receiver.value.uri
    }
  }
}

# Metric Alert - Function App Availability
resource "azurerm_monitor_metric_alert" "function_availability" {
  for_each = var.function_app_ids

  name                = "${var.project_name}-${var.environment}-function-${each.key}-availability-${var.suffix}"
  resource_group_name = var.resource_group_name
  scopes              = [each.value]
  description         = "Function App ${each.key} availability is below threshold"
  severity            = 1
  enabled             = true
  tags                = var.common_tags

  criteria {
    metric_namespace = "Microsoft.Web/sites"
    metric_name      = "Availability"
    aggregation      = "Average"
    operator         = "LessThan"
    threshold        = 95
  }

  action {
    action_group_id = azurerm_monitor_action_group.main.id
  }
}

# Metric Alert - Function App Response Time
resource "azurerm_monitor_metric_alert" "function_response_time" {
  for_each = var.function_app_ids

  name                = "${var.project_name}-${var.environment}-function-${each.key}-response-time-${var.suffix}"
  resource_group_name = var.resource_group_name
  scopes              = [each.value]
  description         = "Function App ${each.key} response time is above threshold"
  severity            = 2
  enabled             = true
  tags                = var.common_tags

  criteria {
    metric_namespace = "Microsoft.Web/sites"
    metric_name      = "HttpResponseTime"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 1000
  }

  action {
    action_group_id = azurerm_monitor_action_group.main.id
  }
}

# Metric Alert - IoT Hub Message Count
resource "azurerm_monitor_metric_alert" "iot_hub_messages" {
  count = var.enable_iot_hub_alerts ? 1 : 0

  name                = "${var.project_name}-${var.environment}-iot-hub-messages-${var.suffix}"
  resource_group_name = var.resource_group_name
  scopes              = [var.iot_hub_id]
  description         = "IoT Hub message count is above threshold"
  severity            = 2
  enabled             = true
  tags                = var.common_tags

  criteria {
    metric_namespace = "Microsoft.Devices/IotHubs"
    metric_name      = "d2c.telemetry.ingress.allProtocol"
    aggregation      = "Total"
    operator         = "GreaterThan"
    threshold        = 10000
  }

  action {
    action_group_id = azurerm_monitor_action_group.main.id
  }
}

# Metric Alert - Cosmos DB Request Units
resource "azurerm_monitor_metric_alert" "cosmos_db_ru" {
  count = var.enable_cosmos_db_alerts ? 1 : 0

  name                = "${var.project_name}-${var.environment}-cosmos-db-ru-${var.suffix}"
  resource_group_name = var.resource_group_name
  scopes              = [var.cosmos_db_id]
  description         = "Cosmos DB request units consumption is above threshold"
  severity            = 2
  enabled             = true
  tags                = var.common_tags

  criteria {
    metric_namespace = "Microsoft.DocumentDB/databaseAccounts"
    metric_name      = "TotalRequestUnits"
    aggregation      = "Total"
    operator         = "GreaterThan"
    threshold        = 1000000
  }

  action {
    action_group_id = azurerm_monitor_action_group.main.id
  }
}

# Metric Alert - SQL Database DTU
resource "azurerm_monitor_metric_alert" "sql_database_dtu" {
  count = var.enable_sql_database_alerts ? 1 : 0

  name                = "${var.project_name}-${var.environment}-sql-db-dtu-${var.suffix}"
  resource_group_name = var.resource_group_name
  scopes              = [var.sql_database_id]
  description         = "SQL Database DTU consumption is above threshold"
  severity            = 2
  enabled             = true
  tags                = var.common_tags

  criteria {
    metric_namespace = "Microsoft.Sql/servers/databases"
    metric_name      = "dtu_consumption_percent"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 80
  }

  action {
    action_group_id = azurerm_monitor_action_group.main.id
  }
}

# Log Alert - Function App Errors
resource "azurerm_monitor_scheduled_query_rules_alert" "function_errors" {
  for_each = var.function_app_ids

  name                = "${var.project_name}-${var.environment}-function-${each.key}-errors-${var.suffix}"
  resource_group_name = var.resource_group_name
  location            = var.location
  description         = "Function App ${each.key} error rate is above threshold"
  enabled             = true
  tags                = var.common_tags

  data_source_id = azurerm_log_analytics_workspace.main.id

  query = <<-EOT
    AppTraces
    | where AppRoleName == "${each.key}"
    | where SeverityLevel >= 3
    | summarize ErrorCount = count() by bin(TimeGenerated, 5m)
    | where ErrorCount > 10
  EOT

  frequency   = 5
  time_window = 15
  severity    = 2

  action {
    action_group = [azurerm_monitor_action_group.main.id]
  }

  trigger {
    operator  = "GreaterThan"
    threshold = 0
  }
}

# Log Alert - High Error Rate
resource "azurerm_monitor_scheduled_query_rules_alert" "high_error_rate" {
  name                = "${var.project_name}-${var.environment}-high-error-rate-${var.suffix}"
  resource_group_name = var.resource_group_name
  location            = var.location
  description         = "High error rate across all services"
  enabled             = true
  tags                = var.common_tags

  data_source_id = azurerm_log_analytics_workspace.main.id

  query = <<-EOT
    AppTraces
    | where SeverityLevel >= 3
    | summarize ErrorCount = count() by bin(TimeGenerated, 5m)
    | where ErrorCount > 50
  EOT

  frequency   = 5
  time_window = 15
  severity    = 1

  action {
    action_group = [azurerm_monitor_action_group.main.id]
  }

  trigger {
    operator  = "GreaterThan"
    threshold = 0
  }
}

# Log Alert - Security Events
resource "azurerm_monitor_scheduled_query_rules_alert" "security_events" {
  name                = "${var.project_name}-${var.environment}-security-events-${var.suffix}"
  resource_group_name = var.resource_group_name
  location            = var.location
  description         = "Security events detected"
  enabled             = true
  tags                = var.common_tags

  data_source_id = azurerm_log_analytics_workspace.main.id

  query = <<-EOT
    SecurityEvent
    | where EventID in (4625, 4624, 4648, 4649, 4650, 4651, 4652, 4653, 4654, 4655, 4656, 4657, 4658, 4659, 4660, 4661, 4662, 4663, 4664, 4665, 4666, 4667, 4668, 4669, 4670, 4671, 4672, 4673, 4674, 4675, 4676, 4677, 4678, 4679, 4680, 4681, 4682, 4683, 4684, 4685, 4686, 4687, 4688, 4689, 4690, 4691, 4692, 4693, 4694, 4695, 4696, 4697, 4698, 4699, 4700, 4701, 4702, 4703, 4704, 4705, 4706, 4707, 4708, 4709, 4710, 4711, 4712, 4713, 4714, 4715, 4716, 4717, 4718, 4719, 4720, 4721, 4722, 4723, 4724, 4725, 4726, 4727, 4728, 4729, 4730, 4731, 4732, 4733, 4734, 4735, 4736, 4737, 4738, 4739, 4740, 4741, 4742, 4743, 4744, 4745, 4746, 4747, 4748, 4749, 4750, 4751, 4752, 4753, 4754, 4755, 4756, 4757, 4758, 4759, 4760, 4761, 4762, 4763, 4764, 4765, 4766, 4767, 4768, 4769, 4770, 4771, 4772, 4773, 4774, 4775, 4776, 4777, 4778, 4779, 4780, 4781, 4782, 4783, 4784, 4785, 4786, 4787, 4788, 4789, 4790, 4791, 4792, 4793, 4794, 4795, 4796, 4797, 4798, 4799, 4800, 4801, 4802, 4803, 4804, 4805, 4806, 4807, 4808, 4809, 4810, 4811, 4812, 4813, 4814, 4815, 4816, 4817, 4818, 4819, 4820, 4821, 4822, 4823, 4824, 4825, 4826, 4827, 4828, 4829, 4830, 4831, 4832, 4833, 4834, 4835, 4836, 4837, 4838, 4839, 4840, 4841, 4842, 4843, 4844, 4845, 4846, 4847, 4848, 4849, 4850, 4851, 4852, 4853, 4854, 4855, 4856, 4857, 4858, 4859, 4860, 4861, 4862, 4863, 4864, 4865, 4866, 4867, 4868, 4869, 4870, 4871, 4872, 4873, 4874, 4875, 4876, 4877, 4878, 4879, 4880, 4881, 4882, 4883, 4884, 4885, 4886, 4887, 4888, 4889, 4890, 4891, 4892, 4893, 4894, 4895, 4896, 4897, 4898, 4899, 4900, 4901, 4902, 4903, 4904, 4905, 4906, 4907, 4908, 4909, 4910, 4911, 4912, 4913, 4914, 4915, 4916, 4917, 4918, 4919, 4920, 4921, 4922, 4923, 4924, 4925, 4926, 4927, 4928, 4929, 4930, 4931, 4932, 4933, 4934, 4935, 4936, 4937, 4938, 4939, 4940, 4941, 4942, 4943, 4944, 4945, 4946, 4947, 4948, 4949, 4950, 4951, 4952, 4953, 4954, 4955, 4956, 4957, 4958, 4959, 4960, 4961, 4962, 4963, 4964, 4965, 4966, 4967, 4968, 4969, 4970, 4971, 4972, 4973, 4974, 4975, 4976, 4977, 4978, 4979, 4980, 4981, 4982, 4983, 4984, 4985, 4986, 4987, 4988, 4989, 4990, 4991, 4992, 4993, 4994, 4995, 4996, 4997, 4998, 4999, 5000)
    | summarize SecurityEventCount = count() by bin(TimeGenerated, 5m)
    | where SecurityEventCount > 5
  EOT

  frequency   = 5
  time_window = 15
  severity    = 1

  action {
    action_group = [azurerm_monitor_action_group.main.id]
  }

  trigger {
    operator  = "GreaterThan"
    threshold = 0
  }
}

# Dashboard
resource "azurerm_dashboard" "main" {
  count = var.enable_dashboard ? 1 : 0

  name                = "${var.project_name}-${var.environment}-dashboard-${var.suffix}"
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.common_tags

  dashboard_properties = jsonencode({
    "lenses" = {
      "0" = {
        "order" = 0
        "parts" = {
          "0" = {
            "position" = {
              "x" = 0
              "y" = 0
              "colSpan" = 6
              "rowSpan" = 4
            }
            "metadata" = {
              "inputs" = [
                {
                  "name" = "options"
                  "value" = {
                    "chart" = {
                      "metrics" = [
                        {
                          "resourceMetadata" = {
                            "id" = "/subscriptions/${var.subscription_id}/resourceGroups/${var.resource_group_name}/providers/Microsoft.Web/sites"
                          }
                          "name" = "Availability"
                          "aggregationType" = 4
                          "namespace" = "Microsoft.Web/sites"
                          "metricVisualization" = {
                            "displayName" = "Availability"
                          }
                        }
                      ]
                      "title" = "Function App Availability"
                      "titleKind" = 1
                      "visualization" = {
                        "chartType" = 2
                        "legendVisualization" = {
                          "isVisible" = true
                          "position" = 2
                          "hideSubtitle" = false
                        }
                        "axisVisualization" = {
                          "x" = {
                            "isVisible" = true
                            "axisType" = 2
                          }
                          "y" = {
                            "isVisible" = true
                            "axisType" = 1
                          }
                        }
                      }
                    }
                  }
                }
              ]
              "type" = "Extension/Microsoft_OperationsManagementSuite_Workspace/PartType/LogsDashboardPart"
              "settings" = {}
            }
          }
        }
      }
    }
  })
}
