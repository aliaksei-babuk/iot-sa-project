# Compute Module - Variables

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

variable "iot_hub_connection_string" {
  description = "Connection string for IoT Hub"
  type        = string
  sensitive   = true
}

variable "event_hub_connection_string" {
  description = "Connection string for Event Hubs"
  type        = string
  sensitive   = true
}

variable "service_bus_connection_string" {
  description = "Connection string for Service Bus"
  type        = string
  sensitive   = true
}

variable "function_app_plan_sku" {
  description = "SKU for Function App Plan"
  type        = string
  default     = "Y1"
}

variable "container_app_environment_sku" {
  description = "SKU for Container App Environment"
  type        = string
  default     = "Consumption"
}

variable "log_analytics_workspace_id" {
  description = "ID of the Log Analytics workspace"
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
