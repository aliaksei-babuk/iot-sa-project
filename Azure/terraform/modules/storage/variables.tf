# Storage Module - Variables

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

variable "vnet_id" {
  description = "ID of the virtual network"
  type        = string
}

variable "subnet_ids" {
  description = "Map of subnet names to IDs"
  type        = map(string)
}

variable "key_vault_id" {
  description = "ID of the Key Vault"
  type        = string
}

variable "key_vault_uri" {
  description = "URI of the Key Vault"
  type        = string
}

variable "cosmos_db_throughput" {
  description = "Throughput for Cosmos DB"
  type        = number
  default     = 400
}

variable "sql_database_sku" {
  description = "SKU for SQL Database"
  type        = string
  default     = "S0"
}

variable "sql_admin_username" {
  description = "Administrator username for SQL Server"
  type        = string
  default     = "sqladmin"
}

variable "sql_admin_password" {
  description = "Administrator password for SQL Server"
  type        = string
  sensitive   = true
  default     = ""
}

variable "azure_ad_admin_login" {
  description = "Azure AD administrator login for SQL Server"
  type        = string
  default     = ""
}

variable "azure_ad_admin_object_id" {
  description = "Azure AD administrator object ID for SQL Server"
  type        = string
  default     = ""
}

variable "enable_private_endpoints" {
  description = "Enable private endpoints for services"
  type        = bool
  default     = true
}

variable "private_dns_zone_names" {
  description = "Map of private DNS zone names"
  type        = map(string)
  default     = {}
}
