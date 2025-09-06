# API Module - Outputs

output "api_management_id" {
  description = "ID of the API Management instance"
  value       = azurerm_api_management.main.id
}

output "api_management_name" {
  description = "Name of the API Management instance"
  value       = azurerm_api_management.main.name
}

output "api_management_gateway_url" {
  description = "Gateway URL of the API Management instance"
  value       = azurerm_api_management.main.gateway_url
}

output "api_management_developer_portal_url" {
  description = "Developer portal URL of the API Management instance"
  value       = azurerm_api_management.main.developer_portal_url
}

output "api_management_management_api_url" {
  description = "Management API URL of the API Management instance"
  value       = azurerm_api_management.main.management_api_url
}

output "api_management_identity" {
  description = "Identity of the API Management instance"
  value       = azurerm_api_management.main.identity
}

output "api_management_api_ids" {
  description = "Map of API names to IDs"
  value = {
    sound_analytics  = azurerm_api_management_api.sound_analytics.id
    device_management = azurerm_api_management_api.device_management.id
    analytics        = azurerm_api_management_api.analytics.id
  }
}

output "api_management_api_names" {
  description = "Map of API names"
  value = {
    sound_analytics  = azurerm_api_management_api.sound_analytics.name
    device_management = azurerm_api_management_api.device_management.name
    analytics        = azurerm_api_management_api.analytics.name
  }
}

output "api_management_product_id" {
  description = "ID of the API Management product"
  value       = azurerm_api_management_product.sound_analytics.id
}

output "api_management_product_name" {
  description = "Name of the API Management product"
  value       = azurerm_api_management_product.sound_analytics.display_name
}

output "api_management_subscription_id" {
  description = "ID of the API Management subscription"
  value       = azurerm_api_management_subscription.main.id
}

output "api_management_subscription_name" {
  description = "Name of the API Management subscription"
  value       = azurerm_api_management_subscription.main.display_name
}

output "front_door_id" {
  description = "ID of the Front Door instance"
  value       = azurerm_cdn_frontdoor_profile.main.id
}

output "front_door_name" {
  description = "Name of the Front Door instance"
  value       = azurerm_cdn_frontdoor_profile.main.name
}

output "front_door_hostname" {
  description = "Hostname of the Front Door instance"
  value       = azurerm_cdn_frontdoor_endpoint.main.host_name
}

output "front_door_endpoint_id" {
  description = "ID of the Front Door endpoint"
  value       = azurerm_cdn_frontdoor_endpoint.main.id
}

output "front_door_origin_group_id" {
  description = "ID of the Front Door origin group"
  value       = azurerm_cdn_frontdoor_origin_group.main.id
}

output "front_door_origin_id" {
  description = "ID of the Front Door origin"
  value       = azurerm_cdn_frontdoor_origin.api_management.id
}

output "front_door_route_id" {
  description = "ID of the Front Door route"
  value       = azurerm_cdn_frontdoor_route.main.id
}

output "front_door_security_policy_id" {
  description = "ID of the Front Door security policy"
  value       = azurerm_cdn_frontdoor_security_policy.main.id
}

output "front_door_firewall_policy_id" {
  description = "ID of the Front Door firewall policy"
  value       = azurerm_cdn_frontdoor_firewall_policy.main.id
}

output "web_app_ids" {
  description = "Map of web app names to IDs"
  value = {
    api      = azurerm_linux_web_app.api.id
    dashboard = azurerm_linux_web_app.dashboard.id
  }
}

output "web_app_names" {
  description = "Map of web app names"
  value = {
    api      = azurerm_linux_web_app.api.name
    dashboard = azurerm_linux_web_app.dashboard.name
  }
}

output "web_app_hostnames" {
  description = "Map of web app hostnames"
  value = {
    api      = azurerm_linux_web_app.api.default_hostname
    dashboard = azurerm_linux_web_app.dashboard.default_hostname
  }
}

output "web_app_identities" {
  description = "Map of web app identities"
  value = {
    api      = azurerm_linux_web_app.api.identity
    dashboard = azurerm_linux_web_app.dashboard.identity
  }
}

output "service_plan_id" {
  description = "ID of the web app service plan"
  value       = azurerm_service_plan.web.id
}

output "service_plan_name" {
  description = "Name of the web app service plan"
  value       = azurerm_service_plan.web.name
}

output "private_endpoint_ids" {
  description = "Map of private endpoint names to IDs"
  value = var.enable_private_endpoints ? {
    api_management = azurerm_private_endpoint.api_management[0].id
  } : {}
}
