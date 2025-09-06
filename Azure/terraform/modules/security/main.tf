# Security Module - Main Configuration

# Key Vault
resource "azurerm_key_vault" "main" {
  name                = "${var.project_name}-${var.environment}-kv-${var.suffix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  tenant_id           = var.tenant_id
  sku_name            = "standard"
  tags                = var.common_tags

  enabled_for_disk_encryption     = true
  enabled_for_deployment          = true
  enabled_for_template_deployment = true
  enable_rbac_authorization       = true
  purge_protection_enabled        = var.environment == "prod" ? true : false
  soft_delete_retention_days      = 90

  network_acls {
    default_action = "Deny"
    bypass         = "AzureServices"
  }

  identity {
    type = "SystemAssigned"
  }
}

# Key Vault Access Policy for Current User
resource "azurerm_key_vault_access_policy" "current_user" {
  key_vault_id = azurerm_key_vault.main.id
  tenant_id    = var.tenant_id
  object_id    = var.object_id

  key_permissions = [
    "Get", "List", "Update", "Create", "Import", "Delete", "Recover", "Backup", "Restore"
  ]

  secret_permissions = [
    "Get", "List", "Set", "Delete", "Recover", "Backup", "Restore"
  ]

  certificate_permissions = [
    "Get", "List", "Update", "Create", "Import", "Delete", "Recover", "Backup", "Restore", "ManageContacts", "ManageIssuers", "GetIssuers", "ListIssuers", "SetIssuers", "DeleteIssuers"
  ]
}

# Key Vault Access Policy for System Assigned Identities
resource "azurerm_key_vault_access_policy" "system_identities" {
  for_each = var.system_identity_object_ids

  key_vault_id = azurerm_key_vault.main.id
  tenant_id    = var.tenant_id
  object_id    = each.value

  key_permissions = [
    "Get", "List"
  ]

  secret_permissions = [
    "Get", "List"
  ]

  certificate_permissions = [
    "Get", "List"
  ]
}

# Key Vault Secrets
resource "azurerm_key_vault_secret" "iot_hub_connection_string" {
  name         = "iot-hub-connection-string"
  value        = var.iot_hub_connection_string
  key_vault_id = azurerm_key_vault.main.id
  tags         = var.common_tags

  depends_on = [azurerm_key_vault_access_policy.current_user]
}

resource "azurerm_key_vault_secret" "event_hub_connection_string" {
  name         = "event-hub-connection-string"
  value        = var.event_hub_connection_string
  key_vault_id = azurerm_key_vault.main.id
  tags         = var.common_tags

  depends_on = [azurerm_key_vault_access_policy.current_user]
}

resource "azurerm_key_vault_secret" "service_bus_connection_string" {
  name         = "service-bus-connection-string"
  value        = var.service_bus_connection_string
  key_vault_id = azurerm_key_vault.main.id
  tags         = var.common_tags

  depends_on = [azurerm_key_vault_access_policy.current_user]
}

resource "azurerm_key_vault_secret" "storage_account_key" {
  name         = "storage-account-key"
  value        = var.storage_account_key
  key_vault_id = azurerm_key_vault.main.id
  tags         = var.common_tags

  depends_on = [azurerm_key_vault_access_policy.current_user]
}

resource "azurerm_key_vault_secret" "cosmos_db_key" {
  name         = "cosmos-db-key"
  value        = var.cosmos_db_key
  key_vault_id = azurerm_key_vault.main.id
  tags         = var.common_tags

  depends_on = [azurerm_key_vault_access_policy.current_user]
}

resource "azurerm_key_vault_secret" "sql_admin_password" {
  name         = "sql-admin-password"
  value        = var.sql_admin_password
  key_vault_id = azurerm_key_vault.main.id
  tags         = var.common_tags

  depends_on = [azurerm_key_vault_access_policy.current_user]
}

# Key Vault Keys
resource "azurerm_key_vault_key" "encryption_key" {
  name         = "encryption-key"
  key_vault_id = azurerm_key_vault.main.id
  key_type     = "RSA"
  key_size     = 2048
  key_opts     = ["decrypt", "encrypt", "sign", "unwrapKey", "verify", "wrapKey"]
  tags         = var.common_tags

  depends_on = [azurerm_key_vault_access_policy.current_user]
}

# Azure Security Center
resource "azurerm_security_center_subscription_pricing" "main" {
  count          = var.enable_security_center ? 1 : 0
  tier           = "Standard"
  resource_type  = "VirtualMachines"
}

resource "azurerm_security_center_subscription_pricing" "storage" {
  count          = var.enable_security_center ? 1 : 0
  tier           = "Standard"
  resource_type  = "StorageAccounts"
}

resource "azurerm_security_center_subscription_pricing" "sql" {
  count          = var.enable_security_center ? 1 : 0
  tier           = "Standard"
  resource_type  = "SqlServers"
}

resource "azurerm_security_center_subscription_pricing" "keyvault" {
  count          = var.enable_security_center ? 1 : 0
  tier           = "Standard"
  resource_type  = "KeyVaults"
}

# Security Center Auto Provisioning
resource "azurerm_security_center_auto_provisioning" "main" {
  count = var.enable_security_center ? 1 : 0
  auto_provision = "On"
}

# Security Center Contact
resource "azurerm_security_center_contact" "main" {
  count = var.enable_security_center && var.security_contact_email != "" ? 1 : 0
  email = var.security_contact_email
  phone = var.security_contact_phone
  alert_notifications = true
  alerts_to_admins    = true
}

# Security Center Workspace
resource "azurerm_security_center_workspace" "main" {
  count        = var.enable_security_center && var.log_analytics_workspace_id != "" ? 1 : 0
  scope        = "/subscriptions/${var.subscription_id}"
  workspace_id = var.log_analytics_workspace_id
}

# Azure Policy Assignments
resource "azurerm_policy_assignment" "encryption_at_rest" {
  count                = var.enable_policy_assignments ? 1 : 0
  name                 = "encryption-at-rest"
  scope                = var.policy_scope
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/86a3cd3a-3f70-4a86-8d47-6719c1a3be0d"
  description          = "Ensure encryption at rest is enabled"
  display_name         = "Encryption at Rest"
}

resource "azurerm_policy_assignment" "https_only" {
  count                = var.enable_policy_assignments ? 1 : 0
  name                 = "https-only"
  scope                = var.policy_scope
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/1b5ca4a6-4715-4df0-8864-4aec62f1d54f"
  description          = "Ensure HTTPS only is enabled"
  display_name         = "HTTPS Only"
}

resource "azurerm_policy_assignment" "min_tls_version" {
  count                = var.enable_policy_assignments ? 1 : 0
  name                 = "min-tls-version"
  scope                = var.policy_scope
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/5365a3e6-2675-4e69-9074-70871f6fc113"
  description          = "Ensure minimum TLS version is set"
  display_name         = "Minimum TLS Version"
}

# Private Endpoint for Key Vault (if enabled)
resource "azurerm_private_endpoint" "key_vault" {
  count               = var.enable_private_endpoints ? 1 : 0
  name                = "${var.project_name}-${var.environment}-kv-pe-${var.suffix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.subnet_ids["private-data"]
  tags                = var.common_tags

  private_service_connection {
    name                           = "keyvault-connection"
    private_connection_resource_id = azurerm_key_vault.main.id
    subresource_names              = ["vault"]
    is_manual_connection           = false
  }
}

# Private DNS Record for Key Vault (if private endpoints enabled)
resource "azurerm_private_dns_a_record" "key_vault" {
  count               = var.enable_private_endpoints ? 1 : 0
  name                = azurerm_key_vault.main.name
  zone_name           = var.private_dns_zone_names["keyvault"]
  resource_group_name = var.resource_group_name
  ttl                 = 300
  records             = [azurerm_private_endpoint.key_vault[0].private_service_connection[0].private_ip_address]
  tags                = var.common_tags
}

# Azure AD Application Registration
resource "azuread_application" "main" {
  count        = var.enable_ad_app_registration ? 1 : 0
  display_name = "${var.project_name}-${var.environment}-app-${var.suffix}"
  owners       = [var.object_id]

  web {
    homepage_url  = "https://${var.project_name}-${var.environment}.azurewebsites.net"
    logout_url    = "https://${var.project_name}-${var.environment}.azurewebsites.net/logout"
    redirect_uris = ["https://${var.project_name}-${var.environment}.azurewebsites.net/auth/callback"]
  }

  api {
    requested_access_token_version = 2
  }

  required_resource_access {
    resource_app_id = "00000003-0000-0000-c000-000000000000" # Microsoft Graph

    resource_access {
      id   = "e1fe6dd8-ba31-4d61-89e7-88639da4683d" # User.Read
      type = "Scope"
    }
  }
}

# Azure AD Service Principal
resource "azuread_service_principal" "main" {
  count          = var.enable_ad_app_registration ? 1 : 0
  application_id = azuread_application.main[0].application_id
  owners         = [var.object_id]
}

# Azure AD Service Principal Password
resource "azuread_service_principal_password" "main" {
  count                = var.enable_ad_app_registration ? 1 : 0
  service_principal_id = azuread_service_principal.main[0].object_id
  display_name         = "Terraform Managed Password"
  end_date             = timeadd(timestamp(), "8760h") # 1 year
}
