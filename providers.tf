terraform {
  required_version = ">= 1.5.0"[cite: 1, 4]
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"[cite: 1, 4]
      version = "~> 3.0"[cite: 1]
    }
    azuread = {
      source  = "hashicorp/azuread"[cite: 1, 4]
      version = "~> 2.0"[cite: 1, 4]
    }
  }
  # Tokenized configuration backend block for external CI/CD injection[cite: 1, 4]
  backend "azurerm" {}[cite: 1, 4]
}

# Hub / Core Edge Connectivity Alias[cite: 1, 4]
provider "azurerm" {
  alias           = "connectivity"[cite: 1]
  subscription_id = var.connectivity_subscription_id[cite: 1]
  features {}
}

# Operations / Central Monitoring Log Scope Alias[cite: 1, 4]
provider "azurerm" {
  alias           = "management"[cite: 1]
  subscription_id = var.management_subscription_id[cite: 1]
  features {}
}

# Client Target Workload Spoke Alias[cite: 1, 4]
provider "azurerm" {
  alias           = "workload"[cite: 1]
  subscription_id = var.workload_subscription_id[cite: 1]
  features {}
}
