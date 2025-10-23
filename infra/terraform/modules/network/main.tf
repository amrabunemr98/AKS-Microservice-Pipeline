resource "azurerm_virtual_network" "this" {
  name                = var.vnet_name
  resource_group_name = var.resource_group_name
  location            = var.location
  address_space       = var.vnet_address_space
  tags                = var.tags
}

resource "azurerm_subnet" "aks" {
  name                 = "${var.vnet_name}-aks"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = [var.aks_subnet_prefix]
}

resource "azurerm_subnet" "acr" {
  name                 = "${var.vnet_name}-acr"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = [var.acr_subnet_prefix]
}

resource "azurerm_subnet" "jumpbox" {
  name                 = "${var.vnet_name}-jumpbox"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = [var.jumpbox_subnet_prefix]
}

resource "azurerm_public_ip" "nat" {
  count               = var.enable_nat_gateway ? 1 : 0
  name                = "${var.vnet_name}-nat-ip"
  resource_group_name = var.resource_group_name
  location            = var.location
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

resource "azurerm_nat_gateway" "this" {
  count               = var.enable_nat_gateway ? 1 : 0
  name                = "${var.vnet_name}-nat-gateway"
  resource_group_name = var.resource_group_name
  location            = var.location
  public_ip_address_ids = [for ip in azurerm_public_ip.nat : ip.id]
  idle_timeout_in_minutes = 30
  tags                = var.tags
}

resource "azurerm_subnet_nat_gateway_association" "aks" {
  count = var.enable_nat_gateway ? 1 : 0

  subnet_id      = azurerm_subnet.aks.id
  nat_gateway_id = azurerm_nat_gateway.this[0].id
}
