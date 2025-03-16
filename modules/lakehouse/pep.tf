resource "azurerm_private_endpoint" "front_pe" {
  name                = "frontprivatendpoint"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg_transit.name
  subnet_id           = azurerm_subnet.transit_plsubnet.id

  private_service_connection {
    name                           = "ple-${local.prefix}-uiapi"
    private_connection_resource_id = azurerm_databricks_workspace.app_workspace.id
    is_manual_connection           = false
    subresource_names              = ["databricks_ui_api"]
  }

  private_dns_zone_group {
    name                 = "private-dns-zone-uiapi"
    private_dns_zone_ids = [azurerm_private_dns_zone.dns_auth_front.id]
  }

  depends_on = [
    azurerm_databricks_workspace.app_workspace
  ]
}

//dataplane
resource "azurerm_private_endpoint" "app_dpcp" {
  name                = "dpcppvtendpoint"
  resource_group_name = azurerm_resource_group.rg_dp.name
  location            = var.location
  subnet_id           = azurerm_subnet.app_plsubnet.id

  private_service_connection {
    name                           = "ple-${local.prefix}-dpcp"
    private_connection_resource_id = azurerm_databricks_workspace.app_workspace.id
    is_manual_connection           = false
    subresource_names              = ["databricks_ui_api"]
  }

  private_dns_zone_group {
    name                 = "app-private-dns-zone-dpcp"
    private_dns_zone_ids = [azurerm_private_dns_zone.dnsdpcp.id]
  }

  depends_on = [
    azurerm_private_endpoint.front_pe
  ]
}