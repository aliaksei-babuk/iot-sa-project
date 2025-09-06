# Networking Module - Outputs

output "vnet_id" {
  description = "ID of the virtual network"
  value       = azurerm_virtual_network.main.id
}

output "vnet_name" {
  description = "Name of the virtual network"
  value       = azurerm_virtual_network.main.name
}

output "vnet_address_space" {
  description = "Address space of the virtual network"
  value       = azurerm_virtual_network.main.address_space
}

output "subnet_ids" {
  description = "Map of subnet names to IDs"
  value = {
    for k, v in azurerm_subnet.subnets : k => v.id
  }
}

output "subnet_names" {
  description = "Map of subnet names"
  value = {
    for k, v in azurerm_subnet.subnets : k => v.name
  }
}

output "subnet_address_prefixes" {
  description = "Map of subnet address prefixes"
  value = {
    for k, v in azurerm_subnet.subnets : k => v.address_prefixes
  }
}

output "network_security_group_ids" {
  description = "Map of NSG names to IDs"
  value = {
    public             = azurerm_network_security_group.public.id
    private_compute    = azurerm_network_security_group.private_compute.id
    private_data       = azurerm_network_security_group.private_data.id
    private_integration = azurerm_network_security_group.private_integration.id
  }
}

output "firewall_id" {
  description = "ID of the Azure Firewall (if enabled)"
  value       = var.enable_firewall ? azurerm_firewall.main[0].id : null
}

output "firewall_public_ip" {
  description = "Public IP of the Azure Firewall (if enabled)"
  value       = var.enable_firewall ? azurerm_public_ip.firewall[0].ip_address : null
}

output "ddos_protection_plan_id" {
  description = "ID of the DDoS Protection Plan (if enabled)"
  value       = var.enable_ddos_protection ? azurerm_network_ddos_protection_plan.main[0].id : null
}

output "private_dns_zone_ids" {
  description = "Map of private DNS zone names to IDs"
  value = var.enable_private_endpoints ? {
    keyvault   = azurerm_private_dns_zone.keyvault[0].id
    storage    = azurerm_private_dns_zone.storage[0].id
    sql        = azurerm_private_dns_zone.sql[0].id
    servicebus = azurerm_private_dns_zone.servicebus[0].id
    eventhubs  = azurerm_private_dns_zone.eventhubs[0].id
  } : {}
}

output "private_dns_zone_names" {
  description = "Map of private DNS zone names"
  value = var.enable_private_endpoints ? {
    keyvault   = azurerm_private_dns_zone.keyvault[0].name
    storage    = azurerm_private_dns_zone.storage[0].name
    sql        = azurerm_private_dns_zone.sql[0].name
    servicebus = azurerm_private_dns_zone.servicebus[0].name
    eventhubs  = azurerm_private_dns_zone.eventhubs[0].name
  } : {}
}
