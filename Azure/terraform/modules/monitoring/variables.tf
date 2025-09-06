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

variable "function_app_ids" {
  description = "Map of function app names to IDs"
  type        = map(string)
  default     = {}
}

variable "container_app_ids" {
  description = "Map of container app names to IDs"
  type        = map(string)
  default     = {}
}

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
