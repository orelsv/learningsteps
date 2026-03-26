terraform {
  backend "azurerm" {
    resource_group_name  = "rg-terraform-state"
    storage_account_name = "tfstatelearningsteps"
    container_name       = "tfstate"
    key                  = "learningsteps/terraform.tfstate"
  }
}
