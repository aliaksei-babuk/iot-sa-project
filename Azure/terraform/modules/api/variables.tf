# API Module - Variables

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

variable "cosmos_db_endpoint" {
  description = "Endpoint of the Cosmos DB account"
  type        = string
}

variable "cosmos_db_key" {
  description = "Primary key of the Cosmos DB account"
  type        = string
  sensitive   = true
}

variable "sql_server_fqdn" {
  description = "FQDN of the SQL Server"
  type        = string
}

variable "sql_database_name" {
  description = "Name of the SQL Database"
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

variable "api_management_sku" {
  description = "SKU for API Management"
  type        = string
  default     = "Developer_1"
  validation {
    condition     = contains(["Developer_1", "Standard_1", "Standard_2", "Standard_3", "Standard_4", "Standard_5", "Premium_1", "Premium_2", "Premium_3", "Premium_4", "Premium_5", "Premium_6", "Premium_7", "Premium_8", "Premium_9", "Premium_10"], var.api_management_sku)
    error_message = "API Management SKU must be a valid SKU name."
  }
}

variable "publisher_name" {
  description = "Publisher name for API Management"
  type        = string
  default     = "Sound Analytics Team"
}

variable "publisher_email" {
  description = "Publisher email for API Management"
  type        = string
  default     = "admin@soundanalytics.com"
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
