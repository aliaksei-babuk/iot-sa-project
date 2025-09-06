# Compute Module - Main Configuration

# Storage Account for Function Apps
resource "azurerm_storage_account" "functions" {
  name                     = "${var.project_name}${var.environment}functions${var.suffix}"
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  tags                     = var.common_tags
}

# App Service Plan for Function Apps
resource "azurerm_service_plan" "functions" {
  name                = "${var.project_name}-${var.environment}-functions-plan-${var.suffix}"
  resource_group_name = var.resource_group_name
  location            = var.location
  os_type             = "Linux"
  sku_name            = var.function_app_plan_sku
  tags                = var.common_tags
}

# Function App - Audio Processing
resource "azurerm_linux_function_app" "audio_processing" {
  name                = "${var.project_name}-${var.environment}-audio-processing-${var.suffix}"
  resource_group_name = var.resource_group_name
  location            = var.location
  service_plan_id     = azurerm_service_plan.functions.id
  tags                = var.common_tags

  storage_account_name       = azurerm_storage_account.functions.name
  storage_account_access_key = azurerm_storage_account.functions.primary_access_key

  site_config {
    application_stack {
      python_version = "3.9"
    }
    always_on = false
    ftps_state = "Disabled"
    http2_enabled = true
    min_tls_version = "1.2"
    scm_min_tls_version = "1.2"
  }

  app_settings = {
    "FUNCTIONS_WORKER_RUNTIME" = "python"
    "FUNCTIONS_EXTENSION_VERSION" = "~4"
    "WEBSITE_RUN_FROM_PACKAGE" = "1"
    "IOT_HUB_CONNECTION_STRING" = var.iot_hub_connection_string
    "EVENT_HUB_CONNECTION_STRING" = var.event_hub_connection_string
    "SERVICE_BUS_CONNECTION_STRING" = var.service_bus_connection_string
    "PYTHON_ENABLE_WORKER_EXTENSIONS" = "1"
  }

  identity {
    type = "SystemAssigned"
  }
}

# Function App - ML Inference
resource "azurerm_linux_function_app" "ml_inference" {
  name                = "${var.project_name}-${var.environment}-ml-inference-${var.suffix}"
  resource_group_name = var.resource_group_name
  location            = var.location
  service_plan_id     = azurerm_service_plan.functions.id
  tags                = var.common_tags

  storage_account_name       = azurerm_storage_account.functions.name
  storage_account_access_key = azurerm_storage_account.functions.primary_access_key

  site_config {
    application_stack {
      python_version = "3.9"
    }
    always_on = false
    ftps_state = "Disabled"
    http2_enabled = true
    min_tls_version = "1.2"
    scm_min_tls_version = "1.2"
  }

  app_settings = {
    "FUNCTIONS_WORKER_RUNTIME" = "python"
    "FUNCTIONS_EXTENSION_VERSION" = "~4"
    "WEBSITE_RUN_FROM_PACKAGE" = "1"
    "EVENT_HUB_CONNECTION_STRING" = var.event_hub_connection_string
    "SERVICE_BUS_CONNECTION_STRING" = var.service_bus_connection_string
    "PYTHON_ENABLE_WORKER_EXTENSIONS" = "1"
  }

  identity {
    type = "SystemAssigned"
  }
}

# Function App - Alert Processing
resource "azurerm_linux_function_app" "alert_processing" {
  name                = "${var.project_name}-${var.environment}-alert-processing-${var.suffix}"
  resource_group_name = var.resource_group_name
  location            = var.location
  service_plan_id     = azurerm_service_plan.functions.id
  tags                = var.common_tags

  storage_account_name       = azurerm_storage_account.functions.name
  storage_account_access_key = azurerm_storage_account.functions.primary_access_key

  site_config {
    application_stack {
      python_version = "3.9"
    }
    always_on = false
    ftps_state = "Disabled"
    http2_enabled = true
    min_tls_version = "1.2"
    scm_min_tls_version = "1.2"
  }

  app_settings = {
    "FUNCTIONS_WORKER_RUNTIME" = "python"
    "FUNCTIONS_EXTENSION_VERSION" = "~4"
    "WEBSITE_RUN_FROM_PACKAGE" = "1"
    "SERVICE_BUS_CONNECTION_STRING" = var.service_bus_connection_string
    "PYTHON_ENABLE_WORKER_EXTENSIONS" = "1"
  }

  identity {
    type = "SystemAssigned"
  }
}

# Container App Environment
resource "azurerm_container_app_environment" "main" {
  name                       = "${var.project_name}-${var.environment}-container-env-${var.suffix}"
  location                   = var.location
  resource_group_name        = var.resource_group_name
  log_analytics_workspace_id = var.log_analytics_workspace_id
  tags                       = var.common_tags

  infrastructure_subnet_id = var.subnet_ids["private-compute"]
  internal_load_balancer_enabled = true
}

# Container App - ML Models
resource "azurerm_container_app" "ml_models" {
  name                         = "${var.project_name}-${var.environment}-ml-models-${var.suffix}"
  container_app_environment_id = azurerm_container_app_environment.main.id
  resource_group_name          = var.resource_group_name
  revision_mode                = "Single"
  tags                         = var.common_tags

  template {
    container {
      name   = "ml-models"
      image  = "mcr.microsoft.com/azureml/base:latest"
      cpu    = 1.0
      memory = "2Gi"

      env {
        name  = "MODEL_PATH"
        value = "/models"
      }

      env {
        name  = "API_PORT"
        value = "8080"
      }
    }

    min_replicas = 1
    max_replicas = 10
  }

  ingress {
    allow_insecure_connections = false
    external_enabled          = true
    target_port               = 8080
    transport                 = "http"
  }
}

# Container App - Analytics
resource "azurerm_container_app" "analytics" {
  name                         = "${var.project_name}-${var.environment}-analytics-${var.suffix}"
  container_app_environment_id = azurerm_container_app_environment.main.id
  resource_group_name          = var.resource_group_name
  revision_mode                = "Single"
  tags                         = var.common_tags

  template {
    container {
      name   = "analytics"
      image  = "mcr.microsoft.com/azureml/base:latest"
      cpu    = 0.5
      memory = "1Gi"

      env {
        name  = "ANALYTICS_PORT"
        value = "8080"
      }
    }

    min_replicas = 1
    max_replicas = 5
  }

  ingress {
    allow_insecure_connections = false
    external_enabled          = true
    target_port               = 8080
    transport                 = "http"
  }
}

# Logic App - Workflow Orchestration
resource "azurerm_logic_app_workflow" "main" {
  name                = "${var.project_name}-${var.environment}-workflow-${var.suffix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.common_tags

  identity {
    type = "SystemAssigned"
  }
}

# Logic App - Alert Workflow
resource "azurerm_logic_app_workflow" "alerts" {
  name                = "${var.project_name}-${var.environment}-alert-workflow-${var.suffix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.common_tags

  identity {
    type = "SystemAssigned"
  }
}

# Event Grid System Topic for Function Apps
resource "azurerm_eventgrid_system_topic" "functions" {
  name                = "${var.project_name}-${var.environment}-functions-events-${var.suffix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  source_arm_resource_id = azurerm_linux_function_app.audio_processing.id
  topic_type          = "Microsoft.Web.Sites"
  tags                = var.common_tags
}

# Event Grid System Topic for Container Apps
resource "azurerm_eventgrid_system_topic" "containers" {
  name                = "${var.project_name}-${var.environment}-containers-events-${var.suffix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  source_arm_resource_id = azurerm_container_app.ml_models.id
  topic_type          = "Microsoft.ContainerApps.ContainerApp"
  tags                = var.common_tags
}

# Private Endpoints for Function Apps (if enabled)
resource "azurerm_private_endpoint" "functions_storage" {
  count               = var.enable_private_endpoints ? 1 : 0
  name                = "${var.project_name}-${var.environment}-functions-storage-pe-${var.suffix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.subnet_ids["private-compute"]
  tags                = var.common_tags

  private_service_connection {
    name                           = "functions-storage-connection"
    private_connection_resource_id = azurerm_storage_account.functions.id
    subresource_names              = ["blob"]
    is_manual_connection           = false
  }
}

# Private DNS Records for Function Apps (if private endpoints enabled)
resource "azurerm_private_dns_a_record" "functions_storage" {
  count               = var.enable_private_endpoints ? 1 : 0
  name                = azurerm_storage_account.functions.name
  zone_name           = var.private_dns_zone_names["storage"]
  resource_group_name = var.resource_group_name
  ttl                 = 300
  records             = [azurerm_private_endpoint.functions_storage[0].private_service_connection[0].private_ip_address]
  tags                = var.common_tags
}
