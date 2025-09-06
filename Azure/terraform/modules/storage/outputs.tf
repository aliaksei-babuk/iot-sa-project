# Storage Module - Outputs

output "storage_account_id" {
  description = "ID of the storage account"
  value       = azurerm_storage_account.main.id
}

output "storage_account_name" {
  description = "Name of the storage account"
  value       = azurerm_storage_account.main.name
}

output "storage_account_key" {
  description = "Primary key of the storage account"
  value       = azurerm_storage_account.main.primary_access_key
  sensitive   = true
}

output "storage_account_connection_string" {
  description = "Connection string of the storage account"
  value       = azurerm_storage_account.main.primary_connection_string
  sensitive   = true
}

output "storage_account_identity" {
  description = "Identity of the storage account"
  value       = azurerm_storage_account.main.identity
}

output "storage_container_names" {
  description = "Map of storage container names"
  value = {
    audio_files     = azurerm_storage_container.audio_files.name
    processed_data  = azurerm_storage_container.processed_data.name
    ml_models       = azurerm_storage_container.ml_models.name
    analytics       = azurerm_storage_container.analytics.name
  }
}

output "cosmos_db_id" {
  description = "ID of the Cosmos DB account"
  value       = azurerm_cosmosdb_account.main.id
}

output "cosmos_db_name" {
  description = "Name of the Cosmos DB account"
  value       = azurerm_cosmosdb_account.main.name
}

output "cosmos_db_endpoint" {
  description = "Endpoint of the Cosmos DB account"
  value       = azurerm_cosmosdb_account.main.endpoint
}

output "cosmos_db_key" {
  description = "Primary key of the Cosmos DB account"
  value       = azurerm_cosmosdb_account.main.primary_key
  sensitive   = true
}

output "cosmos_db_connection_string" {
  description = "Connection string of the Cosmos DB account"
  value       = azurerm_cosmosdb_account.main.connection_strings[0]
  sensitive   = true
}

output "cosmos_db_identity" {
  description = "Identity of the Cosmos DB account"
  value       = azurerm_cosmosdb_account.main.identity
}

output "cosmos_db_database_id" {
  description = "ID of the Cosmos DB database"
  value       = azurerm_cosmosdb_sql_database.main.id
}

output "cosmos_db_database_name" {
  description = "Name of the Cosmos DB database"
  value       = azurerm_cosmosdb_sql_database.main.name
}

output "cosmos_db_container_ids" {
  description = "Map of Cosmos DB container names to IDs"
  value = {
    real_time_data  = azurerm_cosmosdb_sql_container.real_time_data.id
    alerts          = azurerm_cosmosdb_sql_container.alerts.id
    device_metadata = azurerm_cosmosdb_sql_container.device_metadata.id
  }
}

output "cosmos_db_container_names" {
  description = "Map of Cosmos DB container names"
  value = {
    real_time_data  = azurerm_cosmosdb_sql_container.real_time_data.name
    alerts          = azurerm_cosmosdb_sql_container.alerts.name
    device_metadata = azurerm_cosmosdb_sql_container.device_metadata.name
  }
}

output "sql_server_id" {
  description = "ID of the SQL Server"
  value       = azurerm_mssql_server.main.id
}

output "sql_server_name" {
  description = "Name of the SQL Server"
  value       = azurerm_mssql_server.main.name
}

output "sql_server_fqdn" {
  description = "FQDN of the SQL Server"
  value       = azurerm_mssql_server.main.fully_qualified_domain_name
}

output "sql_server_identity" {
  description = "Identity of the SQL Server"
  value       = azurerm_mssql_server.main.identity
}

output "sql_database_id" {
  description = "ID of the SQL Database"
  value       = azurerm_mssql_database.main.id
}

output "sql_database_name" {
  description = "Name of the SQL Database"
  value       = azurerm_mssql_database.main.name
}

output "redis_id" {
  description = "ID of the Redis Cache"
  value       = azurerm_redis_cache.main.id
}

output "redis_name" {
  description = "Name of the Redis Cache"
  value       = azurerm_redis_cache.main.name
}

output "redis_hostname" {
  description = "Hostname of the Redis Cache"
  value       = azurerm_redis_cache.main.hostname
}

output "redis_port" {
  description = "Port of the Redis Cache"
  value       = azurerm_redis_cache.main.port
}

output "redis_ssl_port" {
  description = "SSL port of the Redis Cache"
  value       = azurerm_redis_cache.main.ssl_port
}

output "redis_primary_key" {
  description = "Primary key of the Redis Cache"
  value       = azurerm_redis_cache.main.primary_access_key
  sensitive   = true
}

output "redis_secondary_key" {
  description = "Secondary key of the Redis Cache"
  value       = azurerm_redis_cache.main.secondary_access_key
  sensitive   = true
}

output "redis_connection_string" {
  description = "Connection string of the Redis Cache"
  value       = azurerm_redis_cache.main.primary_connection_string
  sensitive   = true
}

output "private_endpoint_ids" {
  description = "Map of private endpoint names to IDs"
  value = var.enable_private_endpoints ? {
    storage   = azurerm_private_endpoint.storage[0].id
    cosmos_db = azurerm_private_endpoint.cosmos_db[0].id
    sql_server = azurerm_private_endpoint.sql_server[0].id
    redis     = azurerm_private_endpoint.redis[0].id
  } : {}
}
