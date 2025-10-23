variable "resource_group_name" {
  description = "Resource group for the Azure Container Registry."
  type        = string
}

variable "location" {
  description = "Azure region for the registry."
  type        = string
}

variable "name_prefix" {
  description = "Prefix used for naming the registry; must be globally unique when combined with a generated suffix."
  type        = string
}

variable "sku" {
  description = "ACR SKU (e.g. Basic, Standard, Premium)."
  type        = string
  default     = "Standard"
}

variable "private_endpoint_subnet_id" {
  description = "Subnet ID where the ACR private endpoint will be created."
  type        = string
}

variable "virtual_network_id" {
  description = "ID of the virtual network used to link private DNS zones."
  type        = string
}

variable "enable_private_endpoint" {
  description = "Whether to create a private endpoint and DNS zone for the registry."
  type        = bool
  default     = true
}

variable "tags" {
  description = "Common tags for all resources."
  type        = map(string)
  default     = {}
}
