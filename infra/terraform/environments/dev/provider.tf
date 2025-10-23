terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.110"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }

  backend "azurerm" {
    resource_group_name  = "tfstate-rg"
    storage_account_name = "tfstateacct00123"
    container_name       = "tfstate"
    key                  = "microservices-dev.tfstate"
    use_azuread_auth     = true
  }
}

provider "azurerm" {
  features {}
}
