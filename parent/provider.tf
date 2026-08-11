terraform {
  required_version = ">= 1.6.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.81.0"
    }
  }
  backend "azurerm" {
    resource_group_name  = "rg_provider"
    storage_account_name = "aksstorageaccount3"
    container_name       = "aksstoragecont"
    key                  = "parent.aksstoragecont"

  }
}

provider "azurerm" {
  features {}

}