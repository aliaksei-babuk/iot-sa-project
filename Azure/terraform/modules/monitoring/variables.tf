# Monitoring Module - Variables

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

# Note: Removed function_app_ids and container_app_ids as all services now use single Application Insights

variable "iot_hub_id" {
  description = "ID of the IoT Hub"
  type        = string
  default     = ""
}

variable "cosmos_db_id" {
  description = "ID of the Cosmos DB account"
  type        = string
  default     = ""
}

variable "sql_database_id" {
  description = "ID of the SQL Database"
  type        = string
  default     = ""
}

variable "retention_days" {
  description = "Log retention days"
  type        = number
  default     = 30
}

variable "admin_email" {
  description = "Admin email for notifications"
  type        = string
  default     = ""
}

variable "additional_email_receivers" {
  description = "Additional email receivers for alerts"
  type = list(object({
    name  = string
    email = string
  }))
  default = []
}

variable "sms_receivers" {
  description = "SMS receivers for alerts"
  type = list(object({
    name         = string
    country_code = string
    phone_number = string
  }))
  default = []
}

variable "webhook_receivers" {
  description = "Webhook receivers for alerts"
  type = list(object({
    name = string
    uri  = string
  }))
  default = []
}

variable "subscription_id" {
  description = "Azure subscription ID"
  type        = string
  default     = ""
}

variable "enable_dashboard" {
  description = "Enable monitoring dashboard"
  type        = bool
  default     = true
}

variable "enable_cosmos_db_alerts" {
  description = "Enable Cosmos DB monitoring alerts"
  type        = bool
  default     = false
}

variable "enable_sql_database_alerts" {
  description = "Enable SQL Database monitoring alerts"
  type        = bool
  default     = false
}

variable "enable_iot_hub_alerts" {
  description = "Enable IoT Hub monitoring alerts"
  type        = bool
  default     = false
}
