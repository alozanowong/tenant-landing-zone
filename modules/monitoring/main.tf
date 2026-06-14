###############################################################################
# modules/monitoring/main.tf
# MSP ALZ — Monitoring & Observability Module
# Provisions Log Analytics Workspace, Activity Log diagnostics,
# Defender for Cloud contact settings, and auto-provisioning.
###############################################################################

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.90.0, < 4.0.0"
    }
  }
}

resource "azurerm_resource_group" "management" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

###############################################################################
# LOG ANALYTICS WORKSPACE
###############################################################################

resource "azurerm_log_analytics_workspace" "central" {
  name                = var.log_analytics_name
  resource_group_name = azurerm_resource_group.management.name
  location            = azurerm_resource_group.management.location
  sku                 = "PerGB2018"
  retention_in_days   = var.retention_days

  # Prevent accidental destruction of the central log store
  lifecycle {
    prevent_destroy = true
  }

  tags = var.tags
}

###############################################################################
# DEFENDER FOR CLOUD
###############################################################################

resource "azurerm_security_center_subscription_pricing" "vms" {
  count         = var.enable_defender ? 1 : 0
  tier          = "Standard"
  resource_type = "VirtualMachines"
}

resource "azurerm_security_center_subscription_pricing" "sql" {
  count         = var.enable_defender ? 1 : 0
  tier          = "Standard"
  resource_type = "SqlServers"
}

resource "azurerm_security_center_subscription_pricing" "app_services" {
  count         = var.enable_defender ? 1 : 0
  tier          = "Standard"
  resource_type = "AppServices"
}

resource "azurerm_security_center_subscription_pricing" "storage" {
  count         = var.enable_defender ? 1 : 0
  tier          = "Standard"
  resource_type = "StorageAccounts"
}

resource "azurerm_security_center_workspace" "central" {
  count        = var.enable_defender ? 1 : 0
  scope        = "/subscriptions/${var.client_subscription_id}"
  workspace_id = azurerm_log_analytics_workspace.central.id
}
