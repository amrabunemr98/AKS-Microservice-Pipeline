output "virtual_network_id" {
  description = "ID of the created virtual network."
  value       = azurerm_virtual_network.this.id
}

output "virtual_network_name" {
  description = "Name of the created virtual network."
  value       = azurerm_virtual_network.this.name
}

output "aks_subnet_id" {
  description = "ID of the AKS subnet."
  value       = azurerm_subnet.aks.id
}

output "acr_subnet_id" {
  description = "ID of the subnet reserved for the Azure Container Registry private endpoint."
  value       = azurerm_subnet.acr.id
}

output "jumpbox_subnet_id" {
  description = "ID of the management subnet used for the jumpbox."
  value       = azurerm_subnet.jumpbox.id
}

output "nat_gateway_id" {
  description = "ID of the NAT gateway provisioned for outbound access (null when disabled)."
  value       = try(azurerm_nat_gateway.this[0].id, null)
}

output "nat_public_ip_id" {
  description = "ID of the NAT gateway public IP (null when disabled)."
  value       = try(azurerm_public_ip.nat[0].id, null)
}
