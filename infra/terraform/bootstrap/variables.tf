variable "location" {
  description = "Azure region for the remote state resources."
  type        = string
  default     = "eastus"
}

variable "resource_group_name" {
  description = "Name of the resource group for Terraform state."
  type        = string
  default     = "tfstate-rg"
}

variable "storage_account_name" {
  description = "Name of the storage account for Terraform state (must be globally unique)."
  type        = string
  default     = "tfstateacct00123"
}

variable "container_name" {
  description = "Name of the blob container for Terraform state."
  type        = string
  default     = "tfstate"
}

variable "tags" {
  description = "Tags applied to the bootstrap resources."
  type        = map(string)
  default = {
    environment = "terraform-state"
  }
}
