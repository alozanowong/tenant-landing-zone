###############################################################################
# providers.tf
# MSP Azure Landing Zone — Provider & Backend Configuration
# Terraform >= 1.5 | AzureRM >= 3.90
###############################################################################

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.90.0, < 4.0.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = ">= 2.47.0, < 3.0.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.6.0"
    }
  }

  # ---------------------------------------------------------------------------
  # Remote State — Azure Storage Account
  # Tokens are injected at pipeline runtime via `terraform init -backend-config`
  # or via environment variables (ARM_*). Never hardcode values here.
  # ---------------------------------------------------------------------------
  backend "azurerm" {
    # Populated at init time:
    #   -backend-config="resource_group_name=rg-tfstate-msp-prod"
    #   -backend-config="storage_account_name=<sa_name>"
    #   -backend-config="container_name=tfstate"
    #   -backend-config="key=<client_name>/<env>/terraform.tfstate"
    #
    # Pipeline env vars (set as secret variables — never in code):
    #   ARM_CLIENT_ID, ARM_CLIENT_SECRET, ARM_TENANT_ID, ARM_SUBSCRIPTION_ID
  }
}

###############################################################################
# AzureRM — Connectivity / Hub Subscription
###############################################################################

provider "azurerm" {
  alias           = "connectivity"
  subscription_id = var.hub_subscription_id
  tenant_id       = var.tenant_id

  features {
    resource_group {
      prevent_deletion_if_contains_resources = true
    }
    key_vault {
      purge_soft_delete_on_destroy    = false
      recover_soft_deleted_key_vaults = true
    }
    virtual_machine {
      delete_os_disk_on_deletion     = true
      skip_shutdown_and_force_delete = false
    }
  }
}

###############################################################################
# AzureRM — Management Subscription (Governance, Policies, Log Analytics)
###############################################################################

provider "azurerm" {
  alias           = "management"
  subscription_id = var.management_subscription_id
  tenant_id       = var.tenant_id

  features {
    resource_group {
      prevent_deletion_if_contains_resources = true
    }
    key_vault {
      purge_soft_delete_on_destroy    = false
      recover_soft_deleted_key_vaults = true
    }
  }
}

###############################################################################
# AzureRM — Client/Workload Subscription (Spoke)
###############################################################################

provider "azurerm" {
  alias           = "workload"
  subscription_id = var.client_subscription_id
  tenant_id       = var.tenant_id

  features {
    resource_group {
      prevent_deletion_if_contains_resources = true
    }
    key_vault {
      purge_soft_delete_on_destroy    = false
      recover_soft_deleted_key_vaults = true
    }
  }
}

###############################################################################
# Azure AD — Service Principal & Group Management
###############################################################################

provider "azuread" {
  tenant_id = var.tenant_id
}
