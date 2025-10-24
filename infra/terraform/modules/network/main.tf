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
  count                   = var.enable_nat_gateway ? 1 : 0
  name                    = "${var.vnet_name}-nat-gateway"
  resource_group_name     = var.resource_group_name
  location                = var.location
  sku_name                = "Standard"
  idle_timeout_in_minutes = 30
  tags                    = var.tags
}

resource "azurerm_nat_gateway_public_ip_association" "this" {
  count                = var.enable_nat_gateway ? 1 : 0
  nat_gateway_id       = azurerm_nat_gateway.this[0].id
  public_ip_address_id = azurerm_public_ip.nat[0].id
}

resource "azurerm_subnet_nat_gateway_association" "aks" {
  count = var.enable_nat_gateway ? 1 : 0

  subnet_id      = azurerm_subnet.aks.id
  nat_gateway_id = azurerm_nat_gateway.this[0].id
}

resource "azurerm_network_security_group" "aks" {
  count               = var.create_aks_nsg ? 1 : 0
  name                = "${var.vnet_name}-aks-nsg"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

resource "azurerm_network_security_rule" "aks_allow_vnet_inbound" {
  count                       = var.create_aks_nsg ? 1 : 0
  name                        = "Allow-Vnet-Inbound"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "VirtualNetwork"
  destination_address_prefix  = "VirtualNetwork"
  network_security_group_name = azurerm_network_security_group.aks[0].name
  resource_group_name         = var.resource_group_name
}

resource "azurerm_network_security_rule" "aks_allow_lb_inbound" {
  count                       = var.create_aks_nsg ? 1 : 0
  name                        = "Allow-AzureLB-Inbound"
  priority                    = 110
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "AzureLoadBalancer"
  destination_address_prefix  = "VirtualNetwork"
  network_security_group_name = azurerm_network_security_group.aks[0].name
  resource_group_name         = var.resource_group_name
}

resource "azurerm_network_security_rule" "aks_allow_grafana" {
  count                       = var.create_aks_nsg ? 1 : 0
  name                        = "Allow-Grafana"
  priority                    = 120
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = tostring(var.grafana_port)
  source_address_prefix       = var.grafana_source_address_prefix
  destination_address_prefix  = "VirtualNetwork"
  network_security_group_name = azurerm_network_security_group.aks[0].name
  resource_group_name         = var.resource_group_name
}

resource "azurerm_network_security_rule" "aks_allow_prometheus" {
  count                       = var.create_aks_nsg ? 1 : 0
  name                        = "Allow-Prometheus"
  priority                    = 130
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = tostring(var.prometheus_port)
  source_address_prefix       = var.prometheus_source_address_prefix
  destination_address_prefix  = "VirtualNetwork"
  network_security_group_name = azurerm_network_security_group.aks[0].name
  resource_group_name         = var.resource_group_name
}

resource "azurerm_network_security_rule" "aks_allow_vnet_outbound" {
  count                       = var.create_aks_nsg ? 1 : 0
  name                        = "Allow-Vnet-Outbound"
  priority                    = 200
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "VirtualNetwork"
  destination_address_prefix  = "VirtualNetwork"
  network_security_group_name = azurerm_network_security_group.aks[0].name
  resource_group_name         = var.resource_group_name
}

resource "azurerm_network_security_rule" "aks_allow_internet_outbound" {
  count                       = var.create_aks_nsg ? 1 : 0
  name                        = "Allow-Internet-Outbound"
  priority                    = 210
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "VirtualNetwork"
  destination_address_prefix  = "Internet"
  network_security_group_name = azurerm_network_security_group.aks[0].name
  resource_group_name         = var.resource_group_name
}

resource "azurerm_subnet_network_security_group_association" "aks" {
  count = var.create_aks_nsg ? 1 : 0

  subnet_id                 = azurerm_subnet.aks.id
  network_security_group_id = azurerm_network_security_group.aks[0].id
}
