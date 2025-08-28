# azure/main.tf
terraform {
  required_version = ">= 1.6.0"
  required_providers {
    azurerm = { source = "hashicorp/azurerm", version = "~> 3.100" }
    random  = { source = "hashicorp/random",  version = "~> 3.6" }
  }
}

provider "azurerm" { features {} }

variable "prefix"   { type = string, default = "iot-sa" }
variable "location" { type = string, default = "westeurope" }

resource "random_string" "suffix" { length = 5, upper = false, special = false }
locals { name = "${var.prefix}-${random_string.suffix.result}" }

# ---------- RG + Network ----------
resource "azurerm_resource_group" "rg" {
  name     = "${local.name}-rg"
  location = var.location
}
resource "azurerm_virtual_network" "vnet" {
  name                = "${local.name}-vnet"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = ["10.10.0.0/16"]
}
resource "azurerm_subnet" "ingress" {
  name = "snet-ingress"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.10.1.0/24"]
  private_endpoint_network_policies = "Disabled"
}
resource "azurerm_subnet" "processing" {
  name = "snet-processing"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.10.2.0/24"]
  private_endpoint_network_policies = "Disabled"
}
resource "azurerm_subnet" "data" {
  name = "snet-data"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.10.3.0/24"]
  private_endpoint_network_policies = "Disabled"
}

# ---------- Observability ----------
resource "azurerm_log_analytics_workspace" "law" {
  name                = "${local.name}-law"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

# ---------- Storage (ADLS Gen2) ----------
resource "azurerm_storage_account" "sa" {
  name                     = replace("${local.name}sa","-","")
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  is_hns_enabled           = true
  min_tls_version          = "TLS1_2"
}

# ---------- IoT Hub → Event Hubs ----------
resource "azurerm_iothub" "hub" {
  name                = "${local.name}-iothub"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku { name = "S1" capacity = 1 }
  min_tls_version = "1.2"
}

resource "azurerm_eventhub_namespace" "ehns" {
  name                = "${local.name}-ehns"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Standard"
  capacity            = 1
}
resource "azurerm_eventhub" "events" {
  name                = "telemetry"
  namespace_name      = azurerm_eventhub_namespace.ehns.name
  resource_group_name = azurerm_resource_group.rg.name
  partition_count     = 2
  message_retention   = 1
}
resource "azurerm_eventhub_namespace_authorization_rule" "ehns_sender" {
  name                = "iothub-sender"
  namespace_name      = azurerm_eventhub_namespace.ehns.name
  resource_group_name = azurerm_resource_group.rg.name
  send = true
}

resource "azurerm_iothub_endpoint_eventhub" "iothub_eh" {
  resource_group_name = azurerm_resource_group.rg.name
  iothub_name         = azurerm_iothub.hub.name
  name                = "eh-out"
  connection_string   = azurerm_eventhub_namespace_authorization_rule.ehns_sender.primary_connection_string
  entity_path         = azurerm_eventhub.events.name
}
resource "azurerm_iothub_route" "to_eventhub" {
  resource_group_name = azurerm_resource_group.rg.name
  iothub_name         = azurerm_iothub.hub.name
  name = "route-all"
  source = "DeviceMessages"
  endpoint_names = [azurerm_iothub_endpoint_eventhub.iothub_eh.name]
  condition = "true"
  enabled   = true
}

# ---------- Cosmos DB (metadata/queries) ----------
resource "azurerm_cosmosdb_account" "cosmos" {
  name                = "${local.name}-cosmos"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  offer_type          = "Standard"
  kind                = "GlobalDocumentDB"
  consistency_policy { consistency_level = "Session" }
  geo_location { location = azurerm_resource_group.rg.location failover_priority = 0 }
}

# ---------- Container Apps (feature extraction) ----------
resource "azurerm_container_app_environment" "cae" {
  name                       = "${local.name}-cae"
  location                   = azurerm_resource_group.rg.location
  resource_group_name        = azurerm_resource_group.rg.name
  log_analytics_workspace_id = azurerm_log_analytics_workspace.law.id
}
resource "azurerm_container_app" "feature_extractor" {
  name                         = "${local.name}-fe"
  container_app_environment_id = azurerm_container_app_environment.cae.id
  resource_group_name          = azurerm_resource_group.rg.name
  revision_mode                = "Single"
  template {
    container {
      name   = "fe"
      image  = "mcr.microsoft.com/azuredocs/containerapps-helloworld:latest"
      cpu    = 0.5
      memory = "1Gi"
    }
    scale { min_replicas = 0  max_replicas = 5 }
  }
  ingress { external_enabled = false  target_port = 80 }
}

# ---------- Private DNS zones & Private Endpoints ----------
resource "azurerm_private_dns_zone" "iothub"   { name = "privatelink.azure-devices.net"      resource_group_name = azurerm_resource_group.rg.name }
resource "azurerm_private_dns_zone" "servicebus" { name = "privatelink.servicebus.windows.net" resource_group_name = azurerm_resource_group.rg.name }
resource "azurerm_private_dns_zone" "blob"     { name = "privatelink.blob.core.windows.net"   resource_group_name = azurerm_resource_group.rg.name }
resource "azurerm_private_dns_zone" "cosmos"   { name = "privatelink.documents.azure.com"     resource_group_name = azurerm_resource_group.rg.name }

resource "azurerm_private_dns_zone_virtual_network_link" "link_iothub"  { name="link-iothub"  resource_group_name=azurerm_resource_group.rg.name private_dns_zone_name=azurerm_private_dns_zone.iothub.name   virtual_network_id=azurerm_virtual_network.vnet.id }
resource "azurerm_private_dns_zone_virtual_network_link" "link_sb"      { name="link-sb"      resource_group_name=azurerm_resource_group.rg.name private_dns_zone_name=azurerm_private_dns_zone.servicebus.name virtual_network_id=azurerm_virtual_network.vnet.id }
resource "azurerm_private_dns_zone_virtual_network_link" "link_blob"    { name="link-blob"    resource_group_name=azurerm_resource_group.rg.name private_dns_zone_name=azurerm_private_dns_zone.blob.name     virtual_network_id=azurerm_virtual_network.vnet.id }
resource "azurerm_private_dns_zone_virtual_network_link" "link_cosmos"  { name="link-cosmos"  resource_group_name=azurerm_resource_group.rg.name private_dns_zone_name=azurerm_private_dns_zone.cosmos.name   virtual_network_id=azurerm_virtual_network.vnet.id }

# NOTE: one dns zone group per private endpoint (avoids the "MoreThanOnePrivateDnsZoneGroupPerPrivateEndpointNotAllowed" error)
resource "azurerm_private_endpoint" "pe_iothub" {
  name                = "${local.name}-pe-iothub"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = azurerm_subnet.ingress.id
  private_service_connection { name="iothub-psc" is_manual_connection=false private_connection_resource_id=azurerm_iothub.hub.id subresource_names=["iotHub"] }
  private_dns_zone_group { name="iothub-dns" private_dns_zone_ids=[azurerm_private_dns_zone.iothub.id] }
}
resource "azurerm_private_endpoint" "pe_ehns" {
  name                = "${local.name}-pe-ehns"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = azurerm_subnet.processing.id
  private_service_connection { name="ehns-psc" is_manual_connection=false private_connection_resource_id=azurerm_eventhub_namespace.ehns.id subresource_names=["namespace"] }
  private_dns_zone_group { name="ehns-dns" private_dns_zone_ids=[azurerm_private_dns_zone.servicebus.id] }
}
resource "azurerm_private_endpoint" "pe_blob" {
  name                = "${local.name}-pe-blob"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = azurerm_subnet.data.id
  private_service_connection { name="blob-psc" is_manual_connection=false private_connection_resource_id=azurerm_storage_account.sa.id subresource_names=["blob"] }
  private_dns_zone_group { name="blob-dns" private_dns_zone_ids=[azurerm_private_dns_zone.blob.id] }
}
resource "azurerm_private_endpoint" "pe_cosmos" {
  name                = "${local.name}-pe-cosmos"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = azurerm_subnet.data.id
  private_service_connection { name="cosmos-psc" is_manual_connection=false private_connection_resource_id=azurerm_cosmosdb_account.cosmos.id subresource_names=["Sql"] }
  private_dns_zone_group { name="cosmos-dns" private_dns_zone_ids=[azurerm_private_dns_zone.cosmos.id] }
}

# ---------- Outputs ----------
output "resource_group"     { value = azurerm_resource_group.rg.name }
output "iothub_hostname"    { value = azurerm_iothub.hub.hostname }
output "eventhub_namespace" { value = azurerm_eventhub_namespace.ehns.name }
output "eventhub_name"      { value = azurerm_eventhub.events.name }
output "storage_account"    { value = azurerm_storage_account.sa.name }
output "cosmosdb_account"   { value = azurerm_cosmosdb_account.cosmos.name }
