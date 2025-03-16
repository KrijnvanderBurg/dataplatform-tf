terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">=3.43.0"
    }
  }
}

resource "random_string" "naming" {
  special = false
  upper   = false
  length  = 6
}

locals {
  cidr_dp = var.cidr_dp
  cidr_transit = var.cidr_transit
  prefix   = "adb-pl"
  dbfsname = join("", ["dbfs", "${random_string.naming.result}"])
  tags = {
    # env   = var.environment
    owner = "Krijn van der Burg"
  }
}

resource "azurerm_resource_group" "rg_dp" {
  name     = var.rg_dp
  location = var.location
}

resource "azurerm_resource_group" "rg_transit" {
  name     = var.rg_transit
  location = var.location
}