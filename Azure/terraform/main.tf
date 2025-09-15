# Azure IoT Sound Analytics - Main Terraform Configuration
# This configuration deploys a serverless architecture for real-time sound analytics

terraform {
  required_version = ">= 1.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

# Configure the Azure Provider
provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
    key_vault {
      purge_soft_delete_on_destroy    = true
      recover_soft_deleted_key_vaults = true
    }
  }
}

# Data sources
data "azurerm_client_config" "current" {}

# Local values
locals {
  project_name = "iot-sound-analytics"
  environment  = var.environment
  location     = var.location
  suffix       = "ababuk-test"
  
  common_tags = {
    Project     = local.project_name
    Environment = local.environment
    ManagedBy   = "Terraform"
    CreatedBy   = data.azurerm_client_config.current.client_id
  }
}

# Resource Group
resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = local.location
  tags     = local.common_tags
}

# Call networking module
module "networking" {
  source = "./modules/networking"
  
  project_name = local.project_name
  environment  = local.environment
  location     = local.location
  suffix       = local.suffix
  common_tags  = local.common_tags
  
  resource_group_name = azurerm_resource_group.main.name
  vnet_address_space  = var.vnet_address_space
  subnet_configs      = var.subnet_configs
}

# Call IoT services module
module "iot_services" {
  source = "./modules/iot_services"
  
  project_name = local.project_name
  environment  = local.environment
  location     = local.location
  suffix       = local.suffix
  common_tags  = local.common_tags
  
  resource_group_name = azurerm_resource_group.main.name
  vnet_id            = module.networking.vnet_id
  subnet_ids         = module.networking.subnet_ids
  iot_hub_sku        = var.iot_hub_sku
  iot_hub_capacity   = var.iot_hub_capacity
}

# Call compute module
module "compute" {
  source = "./modules/compute"
  
  project_name = local.project_name
  environment  = local.environment
  location     = local.location
  suffix       = local.suffix
  common_tags  = local.common_tags
  
  resource_group_name = azurerm_resource_group.main.name
  vnet_id            = module.networking.vnet_id
  subnet_ids         = module.networking.subnet_ids
  iot_hub_connection_string = module.iot_services.iot_hub_connection_string
  event_hub_connection_string = module.iot_services.event_hub_connection_string
  service_bus_connection_string = module.iot_services.service_bus_connection_string
}

# Call storage module
module "storage" {
  source = "./modules/storage"
  
  project_name = local.project_name
  environment  = local.environment
  location     = local.location
  suffix       = local.suffix
  common_tags  = local.common_tags
  
  resource_group_name = azurerm_resource_group.main.name
  vnet_id            = module.networking.vnet_id
  subnet_ids         = module.networking.subnet_ids
  key_vault_id       = module.security.key_vault_id
  key_vault_uri      = module.security.key_vault_uri
}

# Call analytics module
module "analytics" {
  source = "./modules/analytics"
  
  project_name = local.project_name
  environment  = local.environment
  location     = local.location
  suffix       = local.suffix
  common_tags  = local.common_tags
  
  resource_group_name = azurerm_resource_group.main.name
  event_hub_namespace = module.iot_services.event_hub_namespace
  event_hub_name      = module.iot_services.event_hub_name
  event_hub_namespace_id = module.iot_services.event_hub_namespace_id
  event_hub_shared_access_key = module.iot_services.event_hub_primary_key
  storage_account_id  = module.storage.storage_account_id
  storage_account_name = module.storage.storage_account_name
  storage_account_key = module.storage.storage_account_key
  storage_account_connection_string = module.storage.storage_account_connection_string
  cosmos_db_endpoint  = module.storage.cosmos_db_endpoint
  cosmos_db_key       = module.storage.cosmos_db_key
  cosmos_db_database_id = module.storage.cosmos_db_database_id
}

# Call security module
module "security" {
  source = "./modules/security"
  
  project_name = local.project_name
  environment  = local.environment
  location     = local.location
  suffix       = local.suffix
  common_tags  = local.common_tags
  
  resource_group_name = azurerm_resource_group.main.name
  tenant_id          = data.azurerm_client_config.current.tenant_id
  object_id          = data.azurerm_client_config.current.object_id
}

# Call monitoring module
module "monitoring" {
  source = "./modules/monitoring"
  
  project_name = local.project_name
  environment  = local.environment
  location     = local.location
  suffix       = local.suffix
  common_tags  = local.common_tags
  
  resource_group_name = azurerm_resource_group.main.name
  function_app_ids    = module.compute.function_app_ids
  container_app_ids   = module.compute.container_app_ids
  iot_hub_id         = module.iot_services.iot_hub_id
  cosmos_db_id       = module.storage.cosmos_db_id
  sql_database_id    = module.storage.sql_database_id
}

# Call API module
module "api" {
  source = "./modules/api"
  
  project_name = local.project_name
  environment  = local.environment
  location     = local.location
  suffix       = local.suffix
  common_tags  = local.common_tags
  
  resource_group_name = azurerm_resource_group.main.name
  vnet_id            = module.networking.vnet_id
  subnet_ids         = module.networking.subnet_ids
  cosmos_db_endpoint = module.storage.cosmos_db_endpoint
  cosmos_db_key      = module.storage.cosmos_db_key
  sql_server_fqdn    = module.storage.sql_server_fqdn
  sql_database_name  = module.storage.sql_database_name
  storage_account_name = module.storage.storage_account_name
  storage_account_key  = module.storage.storage_account_key
}