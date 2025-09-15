# Storage Module - Main Configuration

# Storage Account for Blob Storage and Data Lake
resource "azurerm_storage_account" "main" {
  name                     = "${substr(replace(var.project_name, "-", ""), 0, 6)}${var.environment}stor${substr(replace(var.suffix, "-", ""), 0, 6)}"
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"
  is_hns_enabled           = true
  tags                     = var.common_tags

  blob_properties {
    versioning_enabled       = true
    change_feed_enabled      = true
    change_feed_retention_in_days = 7
    allow_nested_items_to_be_public = false
    delete_retention_policy {
      days = 30
    }
    container_delete_retention_policy {
      days = 7
    }
  }

  identity {
    type = "SystemAssigned"
  }
}

# Storage Container for Audio Files
resource "azurerm_storage_container" "audio_files" {
  name                  = "audio-files"
  storage_account_name  = azurerm_storage_account.main.name
  container_access_type = "private"
}

# Storage Container for Processed Data
resource "azurerm_storage_container" "processed_data" {
  name                  = "processed-data"
  storage_account_name  = azurerm_storage_account.main.name
  container_access_type = "private"
}

# Storage Container for ML Models
resource "azurerm_storage_container" "ml_models" {
  name                  = "ml-models"
  storage_account_name  = azurerm_storage_account.main.name
  container_access_type = "private"
}

# Storage Container for Analytics
resource "azurerm_storage_container" "analytics" {
  name                  = "analytics"
  storage_account_name  = azurerm_storage_account.main.name
  container_access_type = "private"
}

# Cosmos DB Account
resource "azurerm_cosmosdb_account" "main" {
  name                = "${var.project_name}-${var.environment}-cosmos-${var.suffix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  offer_type          = "Standard"
  kind                = "GlobalDocumentDB"
  tags                = var.common_tags

  consistency_policy {
    consistency_level       = "Session"
    max_interval_in_seconds = 5
    max_staleness_prefix    = 100
  }

  geo_location {
    location          = var.location
    failover_priority = 0
  }

  capabilities {
    name = "EnableServerless"
  }

  identity {
    type = "SystemAssigned"
  }
}

# Cosmos DB Database
resource "azurerm_cosmosdb_sql_database" "main" {
  name                = "sound-analytics"
  resource_group_name = var.resource_group_name
  account_name        = azurerm_cosmosdb_account.main.name
  # Note: No throughput specified for serverless accounts
}

# Cosmos DB Container for Real-time Data
resource "azurerm_cosmosdb_sql_container" "real_time_data" {
  name                = "real-time-data"
  resource_group_name = var.resource_group_name
  account_name        = azurerm_cosmosdb_account.main.name
  database_name       = azurerm_cosmosdb_sql_database.main.name
  partition_key_paths = ["/deviceId"]
  # Note: No throughput specified for serverless accounts

  indexing_policy {
    indexing_mode = "consistent"

    included_path {
      path = "/*"
    }

    excluded_path {
      path = "/\"_etag\"/?"
    }
  }

  unique_key {
    paths = ["/deviceId", "/timestamp"]
  }
}

# Cosmos DB Container for Alerts
resource "azurerm_cosmosdb_sql_container" "alerts" {
  name                = "alerts"
  resource_group_name = var.resource_group_name
  account_name        = azurerm_cosmosdb_account.main.name
  database_name       = azurerm_cosmosdb_sql_database.main.name
  partition_key_paths = ["/alertId"]
  # Note: No throughput specified for serverless accounts

  indexing_policy {
    indexing_mode = "consistent"

    included_path {
      path = "/*"
    }

    excluded_path {
      path = "/\"_etag\"/?"
    }
  }

  unique_key {
    paths = ["/alertId", "/timestamp"]
  }
}

# Cosmos DB Container for Device Metadata
resource "azurerm_cosmosdb_sql_container" "device_metadata" {
  name                = "device-metadata"
  resource_group_name = var.resource_group_name
  account_name        = azurerm_cosmosdb_account.main.name
  database_name       = azurerm_cosmosdb_sql_database.main.name
  partition_key_paths = ["/deviceId"]
  # Note: No throughput specified for serverless accounts

  indexing_policy {
    indexing_mode = "consistent"

    included_path {
      path = "/*"
    }

    excluded_path {
      path = "/\"_etag\"/?"
    }
  }

  unique_key {
    paths = ["/deviceId"]
  }
}

# SQL Server
resource "azurerm_mssql_server" "main" {
  name                         = "${var.project_name}-${var.environment}-sql-${var.suffix}"
  resource_group_name          = var.resource_group_name
  location                     = var.location
  version                      = "12.0"
  administrator_login          = var.sql_admin_username
  administrator_login_password = var.sql_admin_password
  minimum_tls_version          = "1.2"
  tags                         = var.common_tags

  identity {
    type = "SystemAssigned"
  }

  dynamic "azuread_administrator" {
    for_each = var.azure_ad_admin_login != "" && var.azure_ad_admin_object_id != "" ? [1] : []
    content {
      login_username = var.azure_ad_admin_login
      object_id      = var.azure_ad_admin_object_id
    }
  }
}

# SQL Database
resource "azurerm_mssql_database" "main" {
  name           = "${var.project_name}-${var.environment}-db-${var.suffix}"
  server_id      = azurerm_mssql_server.main.id
  collation      = "SQL_Latin1_General_CP1_CI_AS"
  license_type   = "LicenseIncluded"
  max_size_gb    = 2
  sku_name       = var.sql_database_sku
  tags           = var.common_tags

  short_term_retention_policy {
    retention_days = 7
  }

  long_term_retention_policy {
    weekly_retention  = "P1W"
    monthly_retention = "P1M"
    yearly_retention  = "P1Y"
    week_of_year      = 1
  }

  threat_detection_policy {
    state = "Enabled"
  }
}

# Redis Cache
resource "azurerm_redis_cache" "main" {
  name                = "${var.project_name}-${var.environment}-redis-${var.suffix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  capacity            = 1
  family              = "C"
  sku_name            = "Standard"
  enable_non_ssl_port = false
  minimum_tls_version = "1.2"
  tags                = var.common_tags

  redis_configuration {
    maxmemory_reserved = 2
    maxmemory_delta    = 2
    maxmemory_policy   = "allkeys-lru"
  }
}

# Private Endpoints (if enabled)
resource "azurerm_private_endpoint" "storage" {
  count               = var.enable_private_endpoints ? 1 : 0
  name                = "${var.project_name}-${var.environment}-storage-pe-${var.suffix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.subnet_ids["private-data"]
  tags                = var.common_tags

  private_service_connection {
    name                           = "storage-connection"
    private_connection_resource_id = azurerm_storage_account.main.id
    subresource_names              = ["blob"]
    is_manual_connection           = false
  }
}

resource "azurerm_private_endpoint" "cosmos_db" {
  count               = var.enable_private_endpoints ? 1 : 0
  name                = "${var.project_name}-${var.environment}-cosmos-pe-${var.suffix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.subnet_ids["private-data"]
  tags                = var.common_tags

  private_service_connection {
    name                           = "cosmos-connection"
    private_connection_resource_id = azurerm_cosmosdb_account.main.id
    subresource_names              = ["Sql"]
    is_manual_connection           = false
  }
}

resource "azurerm_private_endpoint" "sql_server" {
  count               = var.enable_private_endpoints ? 1 : 0
  name                = "${var.project_name}-${var.environment}-sql-pe-${var.suffix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.subnet_ids["private-data"]
  tags                = var.common_tags

  private_service_connection {
    name                           = "sql-connection"
    private_connection_resource_id = azurerm_mssql_server.main.id
    subresource_names              = ["sqlServer"]
    is_manual_connection           = false
  }
}

resource "azurerm_private_endpoint" "redis" {
  count               = var.enable_private_endpoints ? 1 : 0
  name                = "${var.project_name}-${var.environment}-redis-pe-${var.suffix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.subnet_ids["private-data"]
  tags                = var.common_tags

  private_service_connection {
    name                           = "redis-connection"
    private_connection_resource_id = azurerm_redis_cache.main.id
    subresource_names              = ["redisCache"]
    is_manual_connection           = false
  }
}

# Private DNS Records (if private endpoints enabled)
resource "azurerm_private_dns_a_record" "storage" {
  count               = var.enable_private_endpoints && contains(keys(var.private_dns_zone_names), "storage") ? 1 : 0
  name                = azurerm_storage_account.main.name
  zone_name           = var.private_dns_zone_names["storage"]
  resource_group_name = var.resource_group_name
  ttl                 = 300
  records             = [azurerm_private_endpoint.storage[0].private_service_connection[0].private_ip_address]
  tags                = var.common_tags
}

resource "azurerm_private_dns_a_record" "cosmos_db" {
  count               = var.enable_private_endpoints && contains(keys(var.private_dns_zone_names), "sql") ? 1 : 0
  name                = azurerm_cosmosdb_account.main.name
  zone_name           = var.private_dns_zone_names["sql"]
  resource_group_name = var.resource_group_name
  ttl                 = 300
  records             = [azurerm_private_endpoint.cosmos_db[0].private_service_connection[0].private_ip_address]
  tags                = var.common_tags
}

resource "azurerm_private_dns_a_record" "sql_server" {
  count               = var.enable_private_endpoints && contains(keys(var.private_dns_zone_names), "sql") ? 1 : 0
  name                = azurerm_mssql_server.main.name
  zone_name           = var.private_dns_zone_names["sql"]
  resource_group_name = var.resource_group_name
  ttl                 = 300
  records             = [azurerm_private_endpoint.sql_server[0].private_service_connection[0].private_ip_address]
  tags                = var.common_tags
}

resource "azurerm_private_dns_a_record" "redis" {
  count               = var.enable_private_endpoints && contains(keys(var.private_dns_zone_names), "storage") ? 1 : 0
  name                = azurerm_redis_cache.main.name
  zone_name           = var.private_dns_zone_names["storage"]
  resource_group_name = var.resource_group_name
  ttl                 = 300
  records             = [azurerm_private_endpoint.redis[0].private_service_connection[0].private_ip_address]
  tags                = var.common_tags
}
