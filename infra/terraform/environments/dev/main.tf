locals {
  name_prefix = "${var.project_name}-${var.environment}"
  tags = merge(
    var.tags,
    {
      environment = var.environment
      project     = var.project_name
    }
  )
}

resource "azurerm_resource_group" "this" {
  name     = "${local.name_prefix}-rg"
  location = var.location
  tags     = local.tags
}

module "network" {
  source = "../../modules/network"

  resource_group_name   = azurerm_resource_group.this.name
  location              = var.location
  vnet_name             = "${local.name_prefix}-vnet"
  vnet_address_space    = var.vnet_address_space
  aks_subnet_prefix     = var.aks_subnet_prefix
  acr_subnet_prefix     = var.acr_subnet_prefix
  jumpbox_subnet_prefix = var.jumpbox_subnet_prefix
  enable_nat_gateway    = var.enable_nat_gateway
  tags                  = local.tags
}

module "acr" {
  source = "../../modules/acr"

  resource_group_name       = azurerm_resource_group.this.name
  location                  = var.location
  name_prefix               = replace(local.name_prefix, "-", "")
  sku                       = var.acr_sku
  enable_private_endpoint   = var.acr_private_endpoint_enabled
  private_endpoint_subnet_id = module.network.acr_subnet_id
  virtual_network_id        = module.network.virtual_network_id
  tags                      = local.tags
}

module "aks" {
  source = "../../modules/aks"

  resource_group_name  = azurerm_resource_group.this.name
  location             = var.location
  cluster_name         = "${local.name_prefix}-aks"
  dns_prefix           = "${local.name_prefix}-dns"
  kubernetes_version   = var.kubernetes_version
  node_count           = var.node_count
  node_vm_size         = var.node_vm_size
  aks_subnet_id        = module.network.aks_subnet_id
  acr_id               = module.acr.id
  authorized_ip_ranges = []
  private_cluster_enabled = true
  tags                 = local.tags
}

resource "azurerm_kubernetes_cluster_node_pool" "user" {
  count                = var.user_node_pool_enabled ? 1 : 0
  name                 = "userpool"
  kubernetes_cluster_id = module.aks.id
  vm_size              = var.user_node_pool_vm_size
  node_count           = var.user_node_pool_node_count
  mode                 = "User"
  vnet_subnet_id       = module.network.aks_subnet_id
  tags                 = local.tags
}

module "jumpbox" {
  source = "../../modules/jumpbox"

  resource_group_name = azurerm_resource_group.this.name
  location            = var.location
  vm_name             = "${local.name_prefix}-jumpbox"
  subnet_id           = module.network.jumpbox_subnet_id
  admin_username      = var.jumpbox_admin_username
  vm_size             = var.jumpbox_vm_size
  ssh_public_key      = file(pathexpand(var.ssh_public_key_path))
  allowed_ssh_cidrs   = var.allowed_ssh_cidrs
  tags                = local.tags
}
