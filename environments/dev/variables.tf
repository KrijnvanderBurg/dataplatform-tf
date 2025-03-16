variable "tenant_id" {
type = string
}

variable "subscription_id" {
  type = string
}

variable "cidr_transit" {
  type = string
}

variable "cidr_dp" {
  type = string
}

variable "rg_transit" {
  type = string
}

variable "rg_dp" {
  type = string
}

variable "location" {
  type = string
}

data "azurerm_client_config" "current" {
}
