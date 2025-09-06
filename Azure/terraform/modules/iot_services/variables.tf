# IoT Services Module - Variables

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

variable "iot_hub_sku" {
  description = "SKU for IoT Hub"
  type        = string
  default     = "S1"
}

variable "iot_hub_capacity" {
  description = "Capacity for IoT Hub"
  type        = number
  default     = 1
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
