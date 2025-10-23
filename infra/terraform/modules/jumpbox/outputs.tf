output "vm_id" {
  description = "Resource ID of the jumpbox VM."
  value       = azurerm_linux_virtual_machine.this.id
}

output "public_ip" {
  description = "Public IP address of the jumpbox."
  value       = azurerm_public_ip.this.ip_address
}

output "private_ip" {
  description = "Private IP address of the jumpbox."
  value       = azurerm_network_interface.this.private_ip_address
}
