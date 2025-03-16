resource "azurerm_virtual_network" "transit_vnet" {
  name                = "${local.prefix}-transit-vnet"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg_transit.name
  address_space       = [var.cidr_transit]
  tags                = local.tags
}

resource "azurerm_network_security_group" "transit_sg" {
  name                = "${local.prefix}-transit-nsg"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg_transit.name
  tags                = local.tags
}

resource "azurerm_network_security_rule" "transit_aad" {
  name                        = "AllowAAD-transit"
  priority                    = 200
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "443"
  source_address_prefix       = "VirtualNetwork"
  destination_address_prefix  = "AzureActiveDirectory"
  resource_group_name         = azurerm_resource_group.rg_transit.name
  network_security_group_name = azurerm_network_security_group.transit_sg.name
}

resource "azurerm_network_security_rule" "transit_azfrontdoor" {
  name                        = "AllowAzureFrontDoor-transit"
  priority                    = 201
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "443"
  source_address_prefix       = "VirtualNetwork"
  destination_address_prefix  = "AzureFrontDoor.Frontend"
  resource_group_name         = azurerm_resource_group.rg_transit.name
  network_security_group_name = azurerm_network_security_group.transit_sg.name
}