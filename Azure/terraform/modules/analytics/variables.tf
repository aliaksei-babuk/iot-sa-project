# Analytics Module - Variables

variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "location" {
  description = "Azure region for resources"
  type        = string
}

variable "suffix" {
  description = "Random suffix for unique resource names"
  type        = string
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "event_hub_namespace" {
  description = "Name of the Event Hub namespace"
  type        = string
}

variable "event_hub_name" {
  description = "Name of the Event Hub"
  type        = string
}

variable "event_hub_namespace_id" {
  description = "ID of the Event Hub namespace"
  type        = string
}

variable "event_hub_shared_access_key" {
  description = "Shared access key for Event Hub"
  type        = string
  sensitive   = true
}

variable "storage_account_id" {
  description = "ID of the storage account"
  type        = string
}

variable "storage_account_name" {
  description = "Name of the storage account"
  type        = string
}

variable "storage_account_key" {
  description = "Primary key of the storage account"
  type        = string
  sensitive   = true
}

variable "storage_account_connection_string" {
  description = "Connection string of the storage account"
  type        = string
  sensitive   = true
}

variable "storage_data_lake_filesystem_id" {
  description = "ID of the Data Lake filesystem"
  type        = string
  default     = ""
}

variable "cosmos_db_endpoint" {
  description = "Endpoint of the Cosmos DB account"
  type        = string
}

variable "cosmos_db_key" {
  description = "Primary key of the Cosmos DB account"
  type        = string
  sensitive   = true
}

variable "cosmos_db_database_id" {
  description = "ID of the Cosmos DB database"
  type        = string
}

variable "application_insights_id" {
  description = "ID of the Application Insights instance"
  type        = string
  default     = ""
}

variable "key_vault_id" {
  description = "ID of the Key Vault"
  type        = string
  default     = ""
}

variable "enable_power_bi" {
  description = "Enable Power BI Embedded"
  type        = bool
  default     = false
}

variable "power_bi_administrators" {
  description = "List of Power BI administrators"
  type        = list(string)
  default     = []
}

variable "enable_synapse" {
  description = "Enable Synapse Analytics"
  type        = bool
  default     = false
}

variable "synapse_sql_admin_login" {
  description = "SQL administrator login for Synapse"
  type        = string
  default     = "sqladmin"
}

variable "synapse_sql_admin_password" {
  description = "SQL administrator password for Synapse"
  type        = string
  sensitive   = true
  default     = ""
}
