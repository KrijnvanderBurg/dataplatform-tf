resource "azurerm_virtual_network" "app_vnet" {
  name                = "${local.prefix}-app-vnet"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg_dp.name
  address_space       = [local.cidr_dp]
  tags                = local.tags
}

resource "azurerm_network_security_group" "app_sg" {
  name                = "${local.prefix}-app-nsg"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg_dp.name
  tags                = local.tags
}

resource "azurerm_network_security_rule" "app_aad" {
  name                        = "AllowAAD-app"
  priority                    = 200
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "443"
  source_address_prefix       = "VirtualNetwork"
  destination_address_prefix  = "AzureActiveDirectory"
  resource_group_name         = azurerm_resource_group.rg_dp.name
  network_security_group_name = azurerm_network_security_group.app_sg.name
}

resource "azurerm_network_security_rule" "app_azfrontdoor" {
  name                        = "AllowAzureFrontDoor-app"
  priority                    = 201
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "443"
  source_address_prefix       = "VirtualNetwork"
  destination_address_prefix  = "AzureFrontDoor.Frontend"
  resource_group_name         = azurerm_resource_group.rg_dp.name
  network_security_group_name = azurerm_network_security_group.app_sg.name
}

// dataplane vnet
resource "azurerm_private_dns_zone" "dnsdpcp" {
  name                = "privatelink.azuredatabricks.net"
  resource_group_name = azurerm_resource_group.rg_dp.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "uiapidnszonevnetlink" {
  name                  = "dpcpvnetconnection"
  resource_group_name   = azurerm_resource_group.rg_dp.name
  private_dns_zone_name = azurerm_private_dns_zone.dnsdpcp.name
  virtual_network_id    = azurerm_virtual_network.app_vnet.id
}