output "resource_group_name" {
  description = "Name of the resource group containing the infrastructure."
  value       = azurerm_resource_group.this.name
}

output "acr_login_server" {
  description = "Container registry login server."
  value       = module.acr.login_server
}

output "aks_cluster_name" {
  description = "Name of the AKS cluster."
  value       = module.aks.name
}

output "aks_cluster_id" {
  description = "Resource ID of the AKS cluster."
  value       = module.aks.id
}

output "aks_kube_config" {
  description = "User kubeconfig for the AKS cluster."
  value       = module.aks.kube_config_raw
  sensitive   = true
}

output "jumpbox_public_ip" {
  description = "Public IP assigned to the jumpbox VM."
  value       = module.jumpbox.public_ip
}
