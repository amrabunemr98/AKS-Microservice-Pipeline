resource "azurerm_kubernetes_cluster" "this" {
  name                = var.cluster_name
  location            = var.location
  resource_group_name = var.resource_group_name
  dns_prefix          = var.dns_prefix
  kubernetes_version  = var.kubernetes_version != "" ? var.kubernetes_version : null
  tags                = var.tags

  sku_tier = "Free"

  default_node_pool {
    name                         = "system"
    vm_size                      = var.node_vm_size
    node_count                   = var.node_count
    vnet_subnet_id               = var.aks_subnet_id
    os_disk_type                 = "Managed"
    type                         = "VirtualMachineScaleSets"
    only_critical_addons_enabled = false
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin    = "azure"
    network_policy    = "azure"
    load_balancer_sku = "standard"
    outbound_type     = "loadBalancer"
  }

  private_cluster_enabled = var.private_cluster_enabled

  dynamic "api_server_access_profile" {
    for_each = var.private_cluster_enabled ? [] : [1]
    content {
      authorized_ip_ranges = var.authorized_ip_ranges
    }
  }

  role_based_access_control_enabled = true
}

resource "azurerm_role_assignment" "acr_pull" {
  scope                = var.acr_id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_kubernetes_cluster.this.kubelet_identity[0].object_id
}

resource "azurerm_kubernetes_cluster_node_pool" "user" {
  count                 = var.user_node_pool_enabled ? 1 : 0
  name                  = "userpool"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.this.id
  vm_size               = var.user_node_pool_vm_size
  node_count            = var.user_node_pool_node_count
  mode                  = "User"
  vnet_subnet_id        = var.aks_subnet_id
  tags                  = var.tags
}
