# Security Module - Outputs

output "key_vault_id" {
  description = "ID of the Key Vault"
  value       = azurerm_key_vault.main.id
}

output "key_vault_name" {
  description = "Name of the Key Vault"
  value       = azurerm_key_vault.main.name
}

output "key_vault_uri" {
  description = "URI of the Key Vault"
  value       = azurerm_key_vault.main.vault_uri
}

output "key_vault_identity" {
  description = "Identity of the Key Vault"
  value       = azurerm_key_vault.main.identity
}

output "key_vault_secret_ids" {
  description = "Map of Key Vault secret names to IDs"
  value = {
    iot_hub_connection_string     = azurerm_key_vault_secret.iot_hub_connection_string.id
    event_hub_connection_string   = azurerm_key_vault_secret.event_hub_connection_string.id
    service_bus_connection_string = azurerm_key_vault_secret.service_bus_connection_string.id
    storage_account_key           = azurerm_key_vault_secret.storage_account_key.id
    cosmos_db_key                 = azurerm_key_vault_secret.cosmos_db_key.id
    sql_admin_password            = azurerm_key_vault_secret.sql_admin_password.id
  }
}

output "key_vault_key_id" {
  description = "ID of the Key Vault encryption key"
  value       = azurerm_key_vault_key.encryption_key.id
}

output "key_vault_key_version" {
  description = "Version of the Key Vault encryption key"
  value       = azurerm_key_vault_key.encryption_key.version
}

output "security_center_pricing_ids" {
  description = "Map of Security Center pricing names to IDs"
  value = var.enable_security_center ? {
    main    = azurerm_security_center_subscription_pricing.main[0].id
    storage = azurerm_security_center_subscription_pricing.storage[0].id
    sql     = azurerm_security_center_subscription_pricing.sql[0].id
    keyvault = azurerm_security_center_subscription_pricing.keyvault[0].id
  } : {}
}

output "security_center_auto_provisioning_id" {
  description = "ID of the Security Center auto provisioning"
  value       = var.enable_security_center ? azurerm_security_center_auto_provisioning.main[0].id : null
}

output "security_center_contact_id" {
  description = "ID of the Security Center contact"
  value       = var.enable_security_center && var.security_contact_email != "" ? azurerm_security_center_contact.main[0].id : null
}

output "security_center_workspace_id" {
  description = "ID of the Security Center workspace"
  value       = var.enable_security_center && var.log_analytics_workspace_id != "" ? azurerm_security_center_workspace.main[0].id : null
}

output "policy_assignment_ids" {
  description = "Map of policy assignment names to IDs"
  value = var.enable_policy_assignments ? {
    encryption_at_rest = azurerm_policy_assignment.encryption_at_rest[0].id
    https_only        = azurerm_policy_assignment.https_only[0].id
    min_tls_version   = azurerm_policy_assignment.min_tls_version[0].id
  } : {}
}

output "private_endpoint_ids" {
  description = "Map of private endpoint names to IDs"
  value = var.enable_private_endpoints ? {
    key_vault = azurerm_private_endpoint.key_vault[0].id
  } : {}
}

output "ad_application_id" {
  description = "ID of the Azure AD application"
  value       = var.enable_ad_app_registration ? azuread_application.main[0].application_id : null
}

output "ad_application_object_id" {
  description = "Object ID of the Azure AD application"
  value       = var.enable_ad_app_registration ? azuread_application.main[0].object_id : null
}

output "ad_service_principal_id" {
  description = "ID of the Azure AD service principal"
  value       = var.enable_ad_app_registration ? azuread_service_principal.main[0].object_id : null
}

output "ad_service_principal_password_id" {
  description = "ID of the Azure AD service principal password"
  value       = var.enable_ad_app_registration ? azuread_service_principal_password.main[0].id : null
}
