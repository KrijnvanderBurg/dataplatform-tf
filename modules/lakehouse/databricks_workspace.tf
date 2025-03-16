resource "azurerm_subnet" "app_public" {
  name                 = "${local.prefix}-app-public"
  resource_group_name  = azurerm_resource_group.rg_dp.name
  virtual_network_name = azurerm_virtual_network.app_vnet.name
  address_prefixes     = [cidrsubnet(local.cidr_dp, 6, 0)]

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

resource "azurerm_subnet_network_security_group_association" "app_public" {
  subnet_id                 = azurerm_subnet.app_public.id
  network_security_group_id = azurerm_network_security_group.app_sg.id
}

variable "private_subnet_endpoints" {
  default = []
}

resource "azurerm_subnet" "app_private" {
  name                 = "${local.prefix}-app-private"
  resource_group_name  = azurerm_resource_group.rg_dp.name
  virtual_network_name = azurerm_virtual_network.app_vnet.name
  address_prefixes     = [cidrsubnet(local.cidr_dp, 6, 1)]

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

  service_endpoints = var.private_subnet_endpoints
}

resource "azurerm_subnet_network_security_group_association" "app_private" {
  subnet_id                 = azurerm_subnet.app_private.id
  network_security_group_id = azurerm_network_security_group.app_sg.id
}


resource "azurerm_subnet" "app_plsubnet" {
  name                                      = "${local.prefix}-app-privatelink"
  resource_group_name                       = azurerm_resource_group.rg_dp.name
  virtual_network_name                      = azurerm_virtual_network.app_vnet.name
  address_prefixes                          = [cidrsubnet(local.cidr_dp, 6, 2)]
}

resource "azurerm_databricks_workspace" "app_workspace" {
  name                                  = "${local.prefix}-app-workspace"
  resource_group_name                   = azurerm_resource_group.rg_dp.name
  location                              = var.location
  sku                                   = "premium"
  tags                                  = local.tags
  public_network_access_enabled         = false                    //use private endpoint
  network_security_group_rules_required = "NoAzureDatabricksRules" //use private endpoint
  customer_managed_key_enabled          = true
  custom_parameters {
    no_public_ip                                         = true
    virtual_network_id                                   = azurerm_virtual_network.app_vnet.id
    private_subnet_name                                  = azurerm_subnet.app_private.name
    public_subnet_name                                   = azurerm_subnet.app_public.name
    public_subnet_network_security_group_association_id  = azurerm_subnet_network_security_group_association.app_public.id
    private_subnet_network_security_group_association_id = azurerm_subnet_network_security_group_association.app_private.id
    storage_account_name                                 = "dbfsapp84527b3"
  }

  depends_on = [
    azurerm_subnet_network_security_group_association.app_public,
    azurerm_subnet_network_security_group_association.app_private
  ]
}