###############################################################################
# main.tf
# MSP Azure Landing Zone — Root Module Orchestration
# Calls governance, networking, identity, and monitoring modules in dependency order.
###############################################################################
# Variable declarations for required inputs referenced in this root module
variable "msp_security_team_group_id" {
  description = "Object ID or group ID for the MSP security team in Azure AD."
  type        = string
}

variable "msp_platform_team_group_id" {
  description = "Object ID or group ID for the MSP platform team in Azure AD."
  type        = string
}

variable "client_admin_group_id" {
  description = "Object ID or group ID for the client administration group in Azure AD."
  type        = string
}

locals {
  rg_hub_networking = format("%s-hub-networking-rg", var.client_name)
}

###############################################################################
# GOVERNANCE — Management Groups, Policies, RBAC
# Deployed first; all other modules depend on MG existence.
###############################################################################

module "governance" {
  source = "./modules/governance"

  providers = {
    azurerm = azurerm.management
  }

  client_name                = var.client_name
  client_display_name        = var.client_display_name
  environment                = var.environment
  management_group_name      = local.management_group_name
  management_group_parent_id = var.management_group_parent_id
  client_subscription_id     = var.client_subscription_id
  primary_location           = var.primary_location
  secondary_location         = var.secondary_location
  policy_enforcement_mode    = var.policy_enforcement_mode
  allowed_vm_skus            = var.allowed_vm_skus
  msp_security_team_group_id = var.msp_security_team_group_id
  msp_platform_team_group_id = var.msp_platform_team_group_id
  client_admin_group_id      = var.client_admin_group_id
  log_analytics_workspace_id = module.monitoring.log_analytics_workspace_id
  tags                       = local.mandatory_tags
}

###############################################################################
# MONITORING — Log Analytics, Diagnostic Settings
# Deployed before networking so VNet flow logs have a destination workspace.
###############################################################################

module "monitoring" {
  source = "./modules/monitoring"

  providers = {
    azurerm = azurerm.management
  }

  resource_group_name    = local.rg_management
  location               = var.primary_location
  log_analytics_name     = local.log_analytics_name
  retention_days         = var.log_analytics_retention_days
  client_subscription_id = var.client_subscription_id
  enable_defender        = var.enable_defender_for_cloud
  tags                   = local.mandatory_tags
}

###############################################################################
# NETWORKING — Hub VNet, Azure Firewall, Bastion
###############################################################################

module "hub_networking" {
  source = "./modules/networking"

  providers = {
    azurerm = azurerm.connectivity
  }

  mode                       = "hub"
  resource_group_name        = local.rg_hub_networking
  location                   = var.primary_location
  vnet_name                  = local.hub_vnet_name
  address_space              = var.hub_vnet_config.address_space
  firewall_subnet_prefix     = var.hub_vnet_config.firewall_subnet_prefix
  bastion_subnet_prefix      = var.hub_vnet_config.bastion_subnet_prefix
  gateway_subnet_prefix      = var.hub_vnet_config.gateway_subnet_prefix
  management_subnet_prefix   = var.hub_vnet_config.management_subnet_prefix
  firewall_name              = local.firewall_name
  firewall_pip_name          = local.firewall_pip_name
  bastion_name               = local.bastion_name
  bastion_pip_name           = local.bastion_pip_name
  log_analytics_workspace_id = module.monitoring.log_analytics_workspace_id
  tags                       = local.mandatory_tags

  depends_on = [module.monitoring]
}

###############################################################################
# NETWORKING — Spoke VNet + Peering to Hub
###############################################################################

module "spoke_networking" {
  source = "./modules/networking"

  providers = {
    azurerm = azurerm.workload
  }

  mode                       = "spoke"
  resource_group_name        = local.rg_spoke_networking
  location                   = var.primary_location
  vnet_name                  = local.spoke_vnet_name
  address_space              = var.spoke_vnet_config.address_space
  workload_subnet_prefix     = var.spoke_vnet_config.workload_subnet_prefix
  data_subnet_prefix         = var.spoke_vnet_config.data_subnet_prefix
  appgw_subnet_prefix        = var.spoke_vnet_config.appgw_subnet_prefix
  hub_vnet_id                = module.hub_networking.vnet_id
  hub_firewall_private_ip    = module.hub_networking.firewall_private_ip
  log_analytics_workspace_id = module.monitoring.log_analytics_workspace_id
  tags                       = local.mandatory_tags

  depends_on = [module.hub_networking]
}

###############################################################################
# IDENTITY — RBAC Role Assignments
###############################################################################

module "identity" {
  source = "./modules/identity"

  providers = {
    azurerm = azurerm.workload
    azuread = azuread
  }

  client_name            = var.client_name
  environment            = var.environment
  client_subscription_id = var.client_subscription_id
  management_group_id    = module.governance.management_group_id
  spoke_vnet_id          = module.spoke_networking.vnet_id
  tags                   = local.mandatory_tags

  depends_on = [module.governance]
}
