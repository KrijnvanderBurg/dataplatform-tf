terraform {
  # backend "azurerm" {	
  #   subscription_id       = "6867b85b-e868-4d21-a71a-0f82b27117b9"
  #   tenant_id             = "9e8cdb6a-eda5-4cca-8b83-b40f0074d999"
  #   resource_group_name   = "rg-init-dev-gwc-01"
  #   storage_account_name  = "sttfbackenddevgwc02"
  #   container_name        = "tfstate"
  #   key                   = "lakehouse.tfstate"
  # }
}

provider "azurerm" {
  subscription_id = var.subscription_id
  tenant_id = var.tenant_id
  features {}
}

module "lakehouse" {
  source = "../../modules/lakehouse"

  cidr_transit = var.cidr_transit
  cidr_dp = var.cidr_dp
  rg_transit = var.rg_transit
  rg_dp = var.rg_dp
  location = var.location  
}
