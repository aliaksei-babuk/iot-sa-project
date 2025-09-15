# Analytics Module - Main Configuration

# Stream Analytics Job
resource "azurerm_stream_analytics_job" "main" {
  name                                     = "${var.project_name}-${var.environment}-stream-analytics-${var.suffix}"
  resource_group_name                      = var.resource_group_name
  location                                 = var.location
  compatibility_level                      = "1.2"
  data_locale                             = "en-US"
  events_late_arrival_max_delay_in_seconds = 5
  events_out_of_order_max_delay_in_seconds = 0
  events_out_of_order_policy               = "Adjust"
  output_error_policy                      = "Drop"
  streaming_units                          = 3
  tags                                     = var.common_tags

  transformation_query = <<EOF
SELECT
    System.Timestamp() AS WindowEnd,
    deviceId,
    COUNT(*) AS EventCount
INTO
    [cosmosdb-output]
FROM
    [eventhub-input] TIMESTAMP BY EventEnqueuedUtcTime
GROUP BY
    TumblingWindow(second, 10), deviceId
EOF

  identity {
    type = "SystemAssigned"
  }
}

# Stream Analytics Input - Event Hub
resource "azurerm_stream_analytics_stream_input_eventhub" "main" {
  name                         = "eventhub-input"
  stream_analytics_job_name    = azurerm_stream_analytics_job.main.name
  resource_group_name          = var.resource_group_name
  eventhub_consumer_group_name = "$Default"
  eventhub_name                = var.event_hub_name
  servicebus_namespace         = var.event_hub_namespace
  shared_access_policy_key     = var.event_hub_shared_access_key
  shared_access_policy_name    = "RootManageSharedAccessKey"

  serialization {
    type     = "Json"
    encoding = "UTF8"
  }
}

# Stream Analytics Output - Cosmos DB
resource "azurerm_stream_analytics_output_cosmosdb" "main" {
  name                     = "cosmosdb-output"
  stream_analytics_job_id  = azurerm_stream_analytics_job.main.id
  cosmosdb_sql_database_id = var.cosmos_db_database_id
  container_name           = "real-time-data"
  document_id              = "deviceId"
  partition_key            = "deviceId"
  cosmosdb_account_key     = var.cosmos_db_key
}

# Stream Analytics Output - Blob Storage
resource "azurerm_stream_analytics_output_blob" "main" {
  name                     = "blob-output"
  stream_analytics_job_name = azurerm_stream_analytics_job.main.name
  resource_group_name      = var.resource_group_name
  storage_account_name     = var.storage_account_name
  storage_account_key      = var.storage_account_key
  storage_container_name   = "processed-data"
  path_pattern             = "sound-analytics/{date}/{time}"
  date_format              = "yyyy-MM-dd"
  time_format              = "HH"
  serialization {
    type            = "Json"
    encoding        = "UTF8"
    format          = "LineSeparated"
  }
}

# Machine Learning Workspace
resource "azurerm_machine_learning_workspace" "main" {
  count               = var.application_insights_id != "" && var.key_vault_id != "" ? 1 : 0
  name                = "${substr(replace(var.project_name, "-", ""), 0, 8)}${var.environment}ml${substr(replace(var.suffix, "-", ""), 0, 8)}"
  location            = var.location
  resource_group_name = var.resource_group_name
  storage_account_id  = var.storage_account_id
  application_insights_id = var.application_insights_id
  key_vault_id            = var.key_vault_id
  tags                = var.common_tags

  identity {
    type = "SystemAssigned"
  }
}

# Machine Learning Compute Cluster
resource "azurerm_machine_learning_compute_cluster" "main" {
  count                         = var.application_insights_id != "" && var.key_vault_id != "" ? 1 : 0
  name                          = "${var.project_name}-${var.environment}-ml-cluster-${var.suffix}"
  location                      = var.location
  vm_priority                   = "Dedicated"
  vm_size                       = "STANDARD_DS2_V2"
  machine_learning_workspace_id = azurerm_machine_learning_workspace.main[0].id
  tags                          = var.common_tags

  scale_settings {
    min_node_count                       = 0
    max_node_count                       = 4
    scale_down_nodes_after_idle_duration = "PT15M"
  }

  identity {
    type = "SystemAssigned"
  }
}

# Machine Learning Compute Instance
resource "azurerm_machine_learning_compute_instance" "main" {
  count                         = var.application_insights_id != "" && var.key_vault_id != "" ? 1 : 0
  name                          = "${var.project_name}-${var.environment}-ml-instance-${var.suffix}"
  location                      = var.location
  machine_learning_workspace_id = azurerm_machine_learning_workspace.main[0].id
  virtual_machine_size          = "STANDARD_DS2_V2"
  tags                          = var.common_tags

  identity {
    type = "SystemAssigned"
  }
}

# Time Series Insights Environment
resource "azurerm_iot_time_series_insights_gen2_environment" "main" {
  name                = "${var.project_name}-${var.environment}-tsi-${var.suffix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku_name            = "L1"
  tags                = var.common_tags

  storage {
    name = "${var.project_name}${var.environment}tsi${var.suffix}"
    key  = var.storage_account_key
  }

  id_properties = ["deviceId"]
}

# Time Series Insights Event Source
resource "azurerm_iot_time_series_insights_event_source_eventhub" "main" {
  name                     = "${var.project_name}-${var.environment}-tsi-eventsource-${var.suffix}"
  location                 = var.location
  environment_id           = azurerm_iot_time_series_insights_gen2_environment.main.id
  eventhub_name            = var.event_hub_name
  namespace_name           = var.event_hub_namespace
  event_source_resource_id = var.event_hub_namespace_id
  shared_access_key        = var.event_hub_shared_access_key
  shared_access_key_name   = "RootManageSharedAccessKey"
  consumer_group_name      = "$Default"
  tags                     = var.common_tags
}

# Power BI Embedded Capacity
resource "azurerm_powerbi_embedded" "main" {
  count               = var.enable_power_bi ? 1 : 0
  name                = "${var.project_name}-${var.environment}-powerbi-${var.suffix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku_name            = "A1"
  administrators       = var.power_bi_administrators
  tags                = var.common_tags
}

# Data Factory
resource "azurerm_data_factory" "main" {
  name                = "${var.project_name}-${var.environment}-datafactory-${var.suffix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.common_tags

  identity {
    type = "SystemAssigned"
  }
}

# Data Factory Linked Service - Storage Account
resource "azurerm_data_factory_linked_service_azure_blob_storage" "storage" {
  name                = "storage-linked-service"
  data_factory_id     = azurerm_data_factory.main.id
  connection_string   = var.storage_account_connection_string
}

# Data Factory Linked Service - Cosmos DB
resource "azurerm_data_factory_linked_service_cosmosdb" "cosmos" {
  name                = "cosmos-linked-service"
  data_factory_id     = azurerm_data_factory.main.id
  account_endpoint    = var.cosmos_db_endpoint
  account_key         = var.cosmos_db_key
}

# Data Factory Pipeline - Data Processing
resource "azurerm_data_factory_pipeline" "data_processing" {
  name        = "data-processing-pipeline"
  data_factory_id = azurerm_data_factory.main.id
  description = "Pipeline for processing sound analytics data"
}

# Data Factory Dataset - Audio Files
resource "azurerm_data_factory_dataset_azure_blob" "audio_files" {
  name                = "audio-files-dataset"
  data_factory_id     = azurerm_data_factory.main.id
  linked_service_name = azurerm_data_factory_linked_service_azure_blob_storage.storage.name
  path                = "audio-files"
  filename            = "*.wav"

  schema_column {
    name = "data"
    type = "String"
  }
}

# Data Factory Dataset - Processed Data
resource "azurerm_data_factory_dataset_azure_blob" "processed_data" {
  name                = "processed-data-dataset"
  data_factory_id     = azurerm_data_factory.main.id
  linked_service_name = azurerm_data_factory_linked_service_azure_blob_storage.storage.name
  path                = "processed-data"
  filename            = "*.json"

  schema_column {
    name = "data"
    type = "String"
  }
}

# Synapse Workspace
resource "azurerm_synapse_workspace" "main" {
  count               = var.enable_synapse ? 1 : 0
  name                = "${var.project_name}-${var.environment}-synapse-${var.suffix}"
  resource_group_name = var.resource_group_name
  location            = var.location
  storage_data_lake_gen2_filesystem_id = var.storage_data_lake_filesystem_id
  sql_administrator_login               = var.synapse_sql_admin_login
  sql_administrator_login_password      = var.synapse_sql_admin_password
  tags                                 = var.common_tags

  identity {
    type = "SystemAssigned"
  }
}

# Synapse SQL Pool
resource "azurerm_synapse_sql_pool" "main" {
  count                = var.enable_synapse ? 1 : 0
  name                 = "${var.project_name}-${var.environment}-sqlpool-${var.suffix}"
  synapse_workspace_id = azurerm_synapse_workspace.main[0].id
  sku_name             = "DW100c"
  create_mode          = "Default"
  tags                 = var.common_tags
}

# Synapse Spark Pool
resource "azurerm_synapse_spark_pool" "main" {
  count                = var.enable_synapse ? 1 : 0
  name                 = "${var.project_name}-${var.environment}-sparkpool-${var.suffix}"
  synapse_workspace_id = azurerm_synapse_workspace.main[0].id
  node_size_family     = "MemoryOptimized"
  node_size            = "Small"
  node_count           = 3
  tags                 = var.common_tags
}
