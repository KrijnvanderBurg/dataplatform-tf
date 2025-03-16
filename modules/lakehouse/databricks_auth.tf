resource "azurerm_subnet" "transit_public" {
  name                 = "${local.prefix}-transit-public"
  resource_group_name  = azurerm_resource_group.rg_transit.name
  virtual_network_name = azurerm_virtual_network.transit_vnet.name
  address_prefixes     = [cidrsubnet(local.cidr_transit, 6, 0)]

  delegation {
    name = "databricks"
    service_delegation {
      name = "Microsoft.Databricks/workspaces"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action",
        "Microsoft.Network/virtualNetworks/subnets/prepareNetworkPolicies/action",
      "Microsoft.Network/virtualNetworks/subnets/unprepareNetworkPolicies/action"]
    }
  }
}

resource "azurerm_subnet_network_security_group_association" "transit_public" {
  subnet_id                 = azurerm_subnet.transit_public.id
  network_security_group_id = azurerm_network_security_group.transit_sg.id
}

variable "transit_private_subnet_endpoints" {
  default = []
}

resource "azurerm_subnet" "transit_private" {
  name                 = "${local.prefix}-transit-private"
  resource_group_name  = azurerm_resource_group.rg_transit.name
  virtual_network_name = azurerm_virtual_network.transit_vnet.name
  address_prefixes     = [cidrsubnet(local.cidr_transit, 6, 1)]

  delegation {
    name = "databricks"
    service_delegation {
      name = "Microsoft.Databricks/workspaces"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action",
        "Microsoft.Network/virtualNetworks/subnets/prepareNetworkPolicies/action",
      "Microsoft.Network/virtualNetworks/subnets/unprepareNetworkPolicies/action"]
    }
  }

  service_endpoints = var.transit_private_subnet_endpoints
}

resource "azurerm_subnet_network_security_group_association" "transit_private" {
  subnet_id                 = azurerm_subnet.transit_private.id
  network_security_group_id = azurerm_network_security_group.transit_sg.id
}


resource "azurerm_subnet" "transit_plsubnet" {
  name                                      = "${local.prefix}-transit-privatelink"
  resource_group_name                       = azurerm_resource_group.rg_transit.name
  virtual_network_name                      = azurerm_virtual_network.transit_vnet.name
  address_prefixes                          = [cidrsubnet(local.cidr_transit, 6, 2)]
}

resource "azurerm_private_endpoint" "transit_auth" {
  name                = "aadauthpvtendpoint-transit"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg_transit.name
  subnet_id           = azurerm_subnet.transit_plsubnet.id

  private_service_connection {
    name                           = "ple-${local.prefix}-auth"
    private_connection_resource_id = azurerm_databricks_workspace.web_auth_workspace.id
    is_manual_connection           = false
    subresource_names              = ["browser_authentication"]
  }

  private_dns_zone_group {
    name                 = "private-dns-zone-auth"
    private_dns_zone_ids = [azurerm_private_dns_zone.dns_auth_front.id]
  }
}

resource "azurerm_databricks_workspace" "web_auth_workspace" {
  name                                  = "${local.prefix}-transit-workspace"
  resource_group_name                   = azurerm_resource_group.rg_transit.name
  location                              = var.location
  sku                                   = "premium"
  tags                                  = local.tags
  public_network_access_enabled         = false                    //use private endpoint
  network_security_group_rules_required = "NoAzureDatabricksRules" //use private endpoint
  customer_managed_key_enabled          = true
  custom_parameters {
    no_public_ip                                         = true
    virtual_network_id                                   = azurerm_virtual_network.transit_vnet.id
    private_subnet_name                                  = azurerm_subnet.transit_private.name
    public_subnet_name                                   = azurerm_subnet.transit_public.name
    public_subnet_network_security_group_association_id  = azurerm_subnet_network_security_group_association.transit_public.id
    private_subnet_network_security_group_association_id = azurerm_subnet_network_security_group_association.transit_private.id
    storage_account_name                                 = local.dbfsname
  }
  depends_on = [
    azurerm_subnet_network_security_group_association.transit_public,
    azurerm_subnet_network_security_group_association.transit_private
  ]
}