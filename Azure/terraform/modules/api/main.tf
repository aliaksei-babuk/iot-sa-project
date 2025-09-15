# API Module - Main Configuration

# API Management
resource "azurerm_api_management" "main" {
  name                = "${var.project_name}-${var.environment}-apim-${var.suffix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  publisher_name      = var.publisher_name
  publisher_email     = var.publisher_email
  sku_name            = var.api_management_sku
  tags                = var.common_tags

  identity {
    type = "SystemAssigned"
  }

  virtual_network_type = "Internal"
  virtual_network_configuration {
    subnet_id = var.subnet_ids["private-integration"]
  }
}

# API Management API - Sound Analytics
resource "azurerm_api_management_api" "sound_analytics" {
  name                = "sound-analytics"
  resource_group_name = var.resource_group_name
  api_management_name = azurerm_api_management.main.name
  revision            = "1"
  display_name        = "Sound Analytics API"
  path                = "sound-analytics"
  protocols           = ["https"]
  service_url         = "https://${var.project_name}-${var.environment}-api-${var.suffix}.azurewebsites.net"
  description         = "API for sound analytics and IoT data processing"
}

# API Management API - Device Management
resource "azurerm_api_management_api" "device_management" {
  name                = "device-management"
  resource_group_name = var.resource_group_name
  api_management_name = azurerm_api_management.main.name
  revision            = "1"
  display_name        = "Device Management API"
  path                = "devices"
  protocols           = ["https"]
  service_url         = "https://${var.project_name}-${var.environment}-api-${var.suffix}.azurewebsites.net"
  description         = "API for IoT device management and configuration"
}

# API Management API - Analytics
resource "azurerm_api_management_api" "analytics" {
  name                = "analytics"
  resource_group_name = var.resource_group_name
  api_management_name = azurerm_api_management.main.name
  revision            = "1"
  display_name        = "Analytics API"
  path                = "analytics"
  protocols           = ["https"]
  service_url         = "https://${var.project_name}-${var.environment}-api-${var.suffix}.azurewebsites.net"
  description         = "API for analytics and reporting"
}

# API Management Product
resource "azurerm_api_management_product" "sound_analytics" {
  product_id            = "sound-analytics"
  api_management_name   = azurerm_api_management.main.name
  resource_group_name   = var.resource_group_name
  display_name          = "Sound Analytics Product"
  description           = "Product for sound analytics APIs"
  subscription_required = true
  approval_required     = false
  published             = true
}

# API Management Product API Association
resource "azurerm_api_management_product_api" "sound_analytics_api" {
  api_name            = azurerm_api_management_api.sound_analytics.name
  product_id          = azurerm_api_management_product.sound_analytics.product_id
  api_management_name = azurerm_api_management.main.name
  resource_group_name = var.resource_group_name
}

resource "azurerm_api_management_product_api" "device_management_api" {
  api_name            = azurerm_api_management_api.device_management.name
  product_id          = azurerm_api_management_product.sound_analytics.product_id
  api_management_name = azurerm_api_management.main.name
  resource_group_name = var.resource_group_name
}

resource "azurerm_api_management_product_api" "analytics_api" {
  api_name            = azurerm_api_management_api.analytics.name
  product_id          = azurerm_api_management_product.sound_analytics.product_id
  api_management_name = azurerm_api_management.main.name
  resource_group_name = var.resource_group_name
}

# API Management Subscription
resource "azurerm_api_management_subscription" "main" {
  api_management_name = azurerm_api_management.main.name
  resource_group_name = var.resource_group_name
  display_name        = "Sound Analytics Subscription"
  product_id          = azurerm_api_management_product.sound_analytics.id
  state               = "active"
}

# Front Door
resource "azurerm_cdn_frontdoor_profile" "main" {
  name                = "${var.project_name}-${var.environment}-fd-${var.suffix}"
  resource_group_name = var.resource_group_name
  sku_name            = "Standard_AzureFrontDoor"
  tags                = var.common_tags
}

# Front Door Origin Group
resource "azurerm_cdn_frontdoor_origin_group" "main" {
  name                     = "${var.project_name}-${var.environment}-fd-og-${var.suffix}"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.main.id

  load_balancing {
    sample_size                        = 4
    successful_samples_required        = 3
    additional_latency_in_milliseconds = 50
  }

  health_probe {
    interval_in_seconds = 240
    path                = "/health"
    protocol            = "Https"
    request_type        = "HEAD"
  }
}

# Front Door Origin
resource "azurerm_cdn_frontdoor_origin" "api_management" {
  name                          = "${var.project_name}-${var.environment}-fd-origin-apim-${var.suffix}"
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.main.id
  enabled                       = true
  host_name                     = azurerm_api_management.main.gateway_url
  http_port                     = 80
  https_port                    = 443
  origin_host_header            = azurerm_api_management.main.gateway_url
  priority                      = 1
  weight                        = 1000
  certificate_name_check_enabled = true

  private_link {
    request_message        = "Request access for API Management"
    target_type           = "Microsoft.ApiManagement/service"
    location              = var.location
    private_link_target_id = azurerm_api_management.main.id
  }
}

# Front Door Endpoint
resource "azurerm_cdn_frontdoor_endpoint" "main" {
  name                     = "${var.project_name}-${var.environment}-fd-endpoint-${var.suffix}"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.main.id
}

# Front Door Route
resource "azurerm_cdn_frontdoor_route" "main" {
  name                          = "${var.project_name}-${var.environment}-fd-route-${var.suffix}"
  cdn_frontdoor_endpoint_id     = azurerm_cdn_frontdoor_endpoint.main.id
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.main.id
  cdn_frontdoor_origin_ids      = [azurerm_cdn_frontdoor_origin.api_management.id]
  enabled                       = true
  forwarding_protocol           = "HttpsOnly"
  https_redirect_enabled        = true
  patterns_to_match             = ["/*"]
  supported_protocols           = ["Http", "Https"]

  cache {
    query_string_caching_behavior = "IgnoreQueryString"
    query_strings                 = []
    compression_enabled           = true
    content_types_to_compress     = ["application/json", "application/xml", "text/css", "text/html", "text/javascript", "text/plain", "text/xml"]
  }
}

# Front Door Security Policy
resource "azurerm_cdn_frontdoor_security_policy" "main" {
  name                     = "${var.project_name}-${var.environment}-fd-security-${var.suffix}"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.main.id

  security_policies {
    firewall {
      cdn_frontdoor_firewall_policy_id = azurerm_cdn_frontdoor_firewall_policy.main.id

      association {
        domain {
          cdn_frontdoor_domain_id = azurerm_cdn_frontdoor_endpoint.main.id
        }
        patterns_to_match = ["/*"]
      }
    }
  }
}

# Front Door Firewall Policy
resource "azurerm_cdn_frontdoor_firewall_policy" "main" {
  name                              = "${var.project_name}-${var.environment}-fd-waf-${var.suffix}"
  resource_group_name               = var.resource_group_name
  sku_name                          = azurerm_cdn_frontdoor_profile.main.sku_name
  enabled                           = true
  mode                              = "Prevention"
  redirect_url                      = "https://www.contoso.com"
  custom_block_response_status_code = 403
  custom_block_response_body        = "PGh0bWw+CjxoZWFkZXI+PGgxPkFjY2VzcyBEZW5pZWQ8L2gxPjwvaGVhZGVyPgo8cD5Zb3VyIHJlcXVlc3QgaGFzIGJlZW4gYmxvY2tlZC48L3A+CjwvaHRtbD4="
  tags                              = var.common_tags

  custom_rule {
    name                           = "RateLimitRule"
    enabled                        = true
    priority                       = 1
    rate_limit_duration_in_minutes = 1
    rate_limit_threshold           = 10
    type                           = "RateLimitRule"
    action                         = "Block"

    match_condition {
      match_variable     = "RemoteAddr"
      operator           = "IPMatch"
      negation_condition = false
      match_values       = ["192.168.1.0/24", "10.0.0.0/24"]
    }
  }

  custom_rule {
    name                           = "GeoBlockRule"
    enabled                        = true
    priority                       = 2
    rate_limit_duration_in_minutes = 1
    rate_limit_threshold           = 10
    type                           = "MatchRule"
    action                         = "Block"

    match_condition {
      match_variable     = "RemoteAddr"
      operator           = "GeoMatch"
      negation_condition = false
      match_values       = ["CN", "RU", "KP"]
    }
  }

  managed_rule {
    type    = "DefaultRuleSet"
    version = "1.0"
    action  = "Block"

    override {
      rule_group_name = "SQLI"

      rule {
        rule_id = "942100"
        enabled = false
        action  = "Block"
      }
    }
  }

  managed_rule {
    type    = "Microsoft_BotManagerRuleSet"
    version = "1.0"
    action  = "Block"
  }
}

# App Service Plan for Web Apps
resource "azurerm_service_plan" "web" {
  name                = "${var.project_name}-${var.environment}-web-plan-${var.suffix}"
  resource_group_name = var.resource_group_name
  location            = var.location
  os_type             = "Linux"
  sku_name            = "B1"
  tags                = var.common_tags
}

# Web App - Main API
resource "azurerm_linux_web_app" "api" {
  name                = "${var.project_name}-${var.environment}-api-${var.suffix}"
  resource_group_name = var.resource_group_name
  location            = var.location
  service_plan_id     = azurerm_service_plan.web.id
  tags                = var.common_tags

  site_config {
    application_stack {
      python_version = "3.9"
    }
    always_on = false
    ftps_state = "Disabled"
    http2_enabled = true
  }

  app_settings = {
    "COSMOS_DB_ENDPOINT" = var.cosmos_db_endpoint
    "COSMOS_DB_KEY" = var.cosmos_db_key
    "SQL_SERVER_FQDN" = var.sql_server_fqdn
    "SQL_DATABASE_NAME" = var.sql_database_name
    "STORAGE_ACCOUNT_NAME" = var.storage_account_name
    "STORAGE_ACCOUNT_KEY" = var.storage_account_key
    "PYTHON_ENABLE_WORKER_EXTENSIONS" = "1"
  }

  identity {
    type = "SystemAssigned"
  }
}

# Web App - Dashboard
resource "azurerm_linux_web_app" "dashboard" {
  name                = "${var.project_name}-${var.environment}-dashboard-${var.suffix}"
  resource_group_name = var.resource_group_name
  location            = var.location
  service_plan_id     = azurerm_service_plan.web.id
  tags                = var.common_tags

  site_config {
    application_stack {
      python_version = "3.9"
    }
    always_on = false
    ftps_state = "Disabled"
    http2_enabled = true
  }

  app_settings = {
    "COSMOS_DB_ENDPOINT" = var.cosmos_db_endpoint
    "COSMOS_DB_KEY" = var.cosmos_db_key
    "SQL_SERVER_FQDN" = var.sql_server_fqdn
    "SQL_DATABASE_NAME" = var.sql_database_name
    "STORAGE_ACCOUNT_NAME" = var.storage_account_name
    "STORAGE_ACCOUNT_KEY" = var.storage_account_key
    "PYTHON_ENABLE_WORKER_EXTENSIONS" = "1"
  }

  identity {
    type = "SystemAssigned"
  }
}

# Private Endpoint for API Management (if enabled)
resource "azurerm_private_endpoint" "api_management" {
  count               = var.enable_private_endpoints ? 1 : 0
  name                = "${var.project_name}-${var.environment}-apim-pe-${var.suffix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.subnet_ids["private-integration"]
  tags                = var.common_tags

  private_service_connection {
    name                           = "apim-connection"
    private_connection_resource_id = azurerm_api_management.main.id
    subresource_names              = ["gateway"]
    is_manual_connection           = false
  }
}

# Private DNS Record for API Management (if private endpoints enabled)
resource "azurerm_private_dns_a_record" "api_management" {
  count               = var.enable_private_endpoints ? 1 : 0
  name                = azurerm_api_management.main.name
  zone_name           = var.private_dns_zone_names["servicebus"]
  resource_group_name = var.resource_group_name
  ttl                 = 300
  records             = [azurerm_private_endpoint.api_management[0].private_service_connection[0].private_ip_address]
  tags                = var.common_tags
}
