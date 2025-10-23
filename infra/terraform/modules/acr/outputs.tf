output "id" {
  description = "Resource ID of the container registry."
  value       = azurerm_container_registry.this.id
}

output "name" {
  description = "Name of the container registry."
  value       = azurerm_container_registry.this.name
}

output "login_server" {
  description = "Login server (FQDN) for the container registry."
  value       = azurerm_container_registry.this.login_server
}

output "private_endpoint_ip" {
  description = "Private IP address allocated to the registry private endpoint."
  value       = try(azurerm_private_endpoint.acr[0].custom_dns_configs[0].ip_addresses[0], null)
}

output "private_dns_zone_id" {
  description = "ID of the private DNS zone used for the registry."
  value       = try(azurerm_private_dns_zone.acr[0].id, null)
}
