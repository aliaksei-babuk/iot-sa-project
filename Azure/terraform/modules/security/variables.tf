# Security Module - Variables

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

variable "tenant_id" {
  description = "Azure AD tenant ID"
  type        = string
}

variable "object_id" {
  description = "Azure AD object ID for current user"
  type        = string
}

variable "subscription_id" {
  description = "Azure subscription ID"
  type        = string
  default     = ""
}

variable "iot_hub_connection_string" {
  description = "Connection string for IoT Hub"
  type        = string
  sensitive   = true
  default     = ""
}

variable "event_hub_connection_string" {
  description = "Connection string for Event Hubs"
  type        = string
  sensitive   = true
  default     = ""
}

variable "service_bus_connection_string" {
  description = "Connection string for Service Bus"
  type        = string
  sensitive   = true
  default     = ""
}

variable "storage_account_key" {
  description = "Primary key of the storage account"
  type        = string
  sensitive   = true
  default     = ""
}

variable "cosmos_db_key" {
  description = "Primary key of the Cosmos DB account"
  type        = string
  sensitive   = true
  default     = ""
}

variable "sql_admin_password" {
  description = "Administrator password for SQL Server"
  type        = string
  sensitive   = true
  default     = ""
}

variable "system_identity_object_ids" {
  description = "Map of system identity names to object IDs"
  type        = map(string)
  default     = {}
}

variable "enable_security_center" {
  description = "Enable Azure Security Center"
  type        = bool
  default     = true
}

variable "security_contact_email" {
  description = "Email for security contact"
  type        = string
  default     = ""
}

variable "security_contact_phone" {
  description = "Phone for security contact"
  type        = string
  default     = ""
}

variable "log_analytics_workspace_id" {
  description = "ID of the Log Analytics workspace"
  type        = string
  default     = ""
}

variable "enable_policy_assignments" {
  description = "Enable Azure Policy assignments"
  type        = bool
  default     = true
}

variable "policy_scope" {
  description = "Scope for policy assignments"
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

variable "subnet_ids" {
  description = "Map of subnet names to IDs"
  type        = map(string)
  default     = {}
}

variable "enable_ad_app_registration" {
  description = "Enable Azure AD application registration"
  type        = bool
  default     = false
}
