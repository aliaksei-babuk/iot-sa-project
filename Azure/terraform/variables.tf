# Azure IoT Sound Analytics - Variables

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

variable "resource_group_name" {
  description = "Name of the Azure resource group"
  type        = string
  default     = "Group1_1"
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "West Europe"
}

variable "vnet_address_space" {
  description = "Address space for the virtual network"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "subnet_configs" {
  description = "Configuration for subnets"
  type = map(object({
    address_prefixes = list(string)
    service_endpoints = list(string)
  }))
  default = {
    "public" = {
      address_prefixes  = ["10.0.1.0/24"]
      service_endpoints = ["Microsoft.Storage", "Microsoft.KeyVault"]
    }
    "private-compute" = {
      address_prefixes  = ["10.0.2.0/24"]
      service_endpoints = ["Microsoft.Storage", "Microsoft.KeyVault", "Microsoft.ServiceBus"]
    }
    "private-data" = {
      address_prefixes  = ["10.0.3.0/24"]
      service_endpoints = ["Microsoft.Storage", "Microsoft.KeyVault", "Microsoft.Sql"]
    }
    "private-integration" = {
      address_prefixes  = ["10.0.4.0/24"]
      service_endpoints = ["Microsoft.Storage", "Microsoft.KeyVault", "Microsoft.ServiceBus"]
    }
  }
}

variable "iot_hub_sku" {
  description = "SKU for IoT Hub"
  type        = string
  default     = "S1"
  validation {
    condition     = contains(["F1", "S1", "S2", "S3", "B1", "B2", "B3"], var.iot_hub_sku)
    error_message = "IoT Hub SKU must be one of: F1, S1, S2, S3, B1, B2, B3."
  }
}

variable "iot_hub_capacity" {
  description = "Capacity for IoT Hub"
  type        = number
  default     = 1
  validation {
    condition     = var.iot_hub_capacity >= 1 && var.iot_hub_capacity <= 10
    error_message = "IoT Hub capacity must be between 1 and 10."
  }
}

variable "cosmos_db_throughput" {
  description = "Throughput for Cosmos DB"
  type        = number
  default     = 400
  validation {
    condition     = var.cosmos_db_throughput >= 400 && var.cosmos_db_throughput <= 1000000
    error_message = "Cosmos DB throughput must be between 400 and 1,000,000."
  }
}

variable "sql_database_sku" {
  description = "SKU for SQL Database"
  type        = string
  default     = "S0"
  validation {
    condition     = contains(["Basic", "S0", "S1", "S2", "S3", "P1", "P2", "P4", "P6", "P11", "P15"], var.sql_database_sku)
    error_message = "SQL Database SKU must be a valid SKU name."
  }
}

variable "function_app_plan_sku" {
  description = "SKU for Function App Plan"
  type        = string
  default     = "Y1"
  validation {
    condition     = contains(["Y1", "EP1", "EP2", "EP3"], var.function_app_plan_sku)
    error_message = "Function App Plan SKU must be one of: Y1, EP1, EP2, EP3."
  }
}

variable "container_app_environment_sku" {
  description = "SKU for Container App Environment"
  type        = string
  default     = "Consumption"
  validation {
    condition     = contains(["Consumption", "Premium"], var.container_app_environment_sku)
    error_message = "Container App Environment SKU must be one of: Consumption, Premium."
  }
}

variable "enable_monitoring" {
  description = "Enable monitoring and alerting"
  type        = bool
  default     = true
}

variable "enable_security_center" {
  description = "Enable Azure Security Center"
  type        = bool
  default     = true
}

variable "enable_ddos_protection" {
  description = "Enable DDoS Protection"
  type        = bool
  default     = false
}

variable "retention_days" {
  description = "Log retention days"
  type        = number
  default     = 30
  validation {
    condition     = var.retention_days >= 1 && var.retention_days <= 365
    error_message = "Retention days must be between 1 and 365."
  }
}

variable "backup_retention_days" {
  description = "Backup retention days"
  type        = number
  default     = 7
  validation {
    condition     = var.backup_retention_days >= 1 && var.backup_retention_days <= 365
    error_message = "Backup retention days must be between 1 and 365."
  }
}

variable "allowed_ip_addresses" {
  description = "List of allowed IP addresses for access"
  type        = list(string)
  default     = []
}

variable "admin_email" {
  description = "Admin email for notifications"
  type        = string
  default     = ""
}

variable "notification_phone" {
  description = "Phone number for SMS notifications"
  type        = string
  default     = ""
}

variable "enable_private_endpoints" {
  description = "Enable private endpoints for services"
  type        = bool
  default     = true
}

variable "enable_encryption_at_rest" {
  description = "Enable encryption at rest for all services"
  type        = bool
  default     = true
}

variable "enable_encryption_in_transit" {
  description = "Enable encryption in transit"
  type        = bool
  default     = true
}

variable "enable_audit_logging" {
  description = "Enable audit logging"
  type        = bool
  default     = true
}

variable "compliance_standards" {
  description = "Compliance standards to implement"
  type        = list(string)
  default     = ["GDPR", "SOC2", "ISO27001"]
  validation {
    condition = alltrue([
      for standard in var.compliance_standards : 
      contains(["GDPR", "SOC2", "ISO27001", "HIPAA", "PCI-DSS"], standard)
    ])
    error_message = "Compliance standards must be from the approved list: GDPR, SOC2, ISO27001, HIPAA, PCI-DSS."
  }
}
