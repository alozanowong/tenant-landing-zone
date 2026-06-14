###############################################################################
# modules/identity/main.tf
# MSP ALZ — Identity & RBAC Module
# Provisions Azure AD groups for RBAC and scoped role assignments
# on the client spoke subscription.
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
  }
}

###############################################################################
# AZURE AD GROUPS — Client-Scoped
###############################################################################

resource "azuread_group" "client_workload_owners" {
  display_name     = "grp-${var.client_name}-${var.environment}-workload-owners"
  mail_enabled     = false
  security_enabled = true
  description      = "Members have Owner access scoped to client ${var.client_name} ${var.environment} workload resource groups only."
}

resource "azuread_group" "client_workload_contributors" {
  display_name     = "grp-${var.client_name}-${var.environment}-workload-contributors"
  mail_enabled     = false
  security_enabled = true
  description      = "Members have Contributor access to ${var.client_name} ${var.environment} workload resources."
}

resource "azuread_group" "client_network_readers" {
  display_name     = "grp-${var.client_name}-${var.environment}-network-readers"
  mail_enabled     = false
  security_enabled = true
  description      = "Read-only access to ${var.client_name} ${var.environment} networking resources."
}

###############################################################################
# ROLE ASSIGNMENTS — Spoke Subscription Scope
###############################################################################

resource "azurerm_role_assignment" "workload_owner_subscription" {
  scope                = "/subscriptions/${var.client_subscription_id}"
  role_definition_name = "Owner"
  principal_id         = azuread_group.client_workload_owners.id
  description          = "Full ownership of client workload subscription scoped to ${var.client_name} ${var.environment}."
}

resource "azurerm_role_assignment" "workload_contributor_subscription" {
  scope                = "/subscriptions/${var.client_subscription_id}"
  role_definition_name = "Contributor"
  principal_id         = azuread_group.client_workload_contributors.id
  description          = "Contributor access to deploy and manage workload resources."
}

resource "azurerm_role_assignment" "network_reader_vnet" {
  scope                = var.spoke_vnet_id
  role_definition_name = "Network Contributor"
  principal_id         = azuread_group.client_network_readers.id
  description          = "Network Contributor on Spoke VNet for client network team visibility."
}

###############################################################################
# ROLE ASSIGNMENTS — Management Group Scope (cross-cutting)
###############################################################################

resource "azurerm_role_assignment" "workload_contributor_mg" {
  scope                = var.management_group_id
  role_definition_name = "Reader"
  principal_id         = azuread_group.client_workload_contributors.id
  description          = "Elevated to Reader at MG level so contributors can see policy compliance state."
}
