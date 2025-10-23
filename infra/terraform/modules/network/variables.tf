variable "resource_group_name" {
  description = "Name of the resource group where the virtual network will be created."
  type        = string
}

variable "location" {
  description = "Azure region for the virtual network."
  type        = string
}

variable "vnet_name" {
  description = "Name of the Azure virtual network."
  type        = string
}

variable "vnet_address_space" {
  description = "CIDR blocks applied to the virtual network."
  type        = list(string)
}

variable "aks_subnet_prefix" {
  description = "CIDR block for the AKS node subnet."
  type        = string
}

variable "acr_subnet_prefix" {
  description = "CIDR block for the private endpoint subnet used by ACR."
  type        = string
}

variable "jumpbox_subnet_prefix" {
  description = "CIDR block for the management (jumpbox) subnet."
  type        = string
}

variable "tags" {
  description = "Common resource tags."
  type        = map(string)
  default     = {}
}
