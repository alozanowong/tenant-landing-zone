# =============================================================================
# Root Orchestration Layer — Multi-Cloud Tenant Landing Zone
# =============================================================================

# -----------------------------------------------------------------------------
# Data Lookups: Entra ID Platform Boundaries
# -----------------------------------------------------------------------------
data "azuread_group" "msp_platform_team" {
  display_name     = "MSP-Platform-Engineers"
  security_enabled = true
}

data "azuread_group" "msp_security_team" {
  display_name     = "MSP-Security-Operations"
  security_enabled = true
}

data "azuread_group" "client_admin" {
  display_name     = "Client-Hub-Administrators"
  security_enabled = true
}

# -----------------------------------------------------------------------------
# Core Foundation Module: Management Groups & Policy Compliance
# -----------------------------------------------------------------------------
module "governance" {
  source = "./modules/governance"

  client_name                = var.client_name
  client_display_name        = var.client_display_name
  management_group_parent_id = var.management_group_parent_id
  policy_enforcement_mode    = var.policy_enforcement_mode
  allowed_vm_skus            = var.allowed_vm_skus
  
  # Aligned parameters to match child variables exactly
  environment                = var.environment
  management_group_name      = format("mg-%s-%s", var.client_name, var.environment)
  client_subscription_id     = var.client_subscription_id
  primary_location           = var.location
  secondary_location         = "eastus2" # Paired regional safety fallback

  # Entra ID Mappings
  msp_platform_team_group_id = data.azuread_group.msp_platform_team.id
  msp_security_team_group_id = data.azuread_group.msp_security_team.id
  client_admin_group_id      = data.azuread_group.client_admin.id

  providers = {
    azurerm = azurerm.management
  }
}

# -----------------------------------------------------------------------------
# Operational Core Module: Central Monitoring & SIEM Engineering
# -----------------------------------------------------------------------------
module "monitoring" {
  source     = "./modules/monitoring"
  depends_on = [module.governance]

  client_name     = var.client_name
  environment     = var.environment
  location        = var.location
  retention_days  = var.retention_days
  enable_defender = var.enable_defender

  providers = {
    azurerm = azurerm.management
  }
}

# -----------------------------------------------------------------------------
# Connectivity Fabric Modules: Shared Hub & Isolated Spoke VNets
# -----------------------------------------------------------------------------
module "hub_networking" {
  source     = "./modules/networking"
  depends_on = [module.monitoring]

  mode                    = "hub"
  client_name             = var.client_name
  environment             = var.environment
  location                = var.location
  address_space           = var.hub_vnet_config.address_space
  firewall_subnet_prefix  = var.hub_vnet_config.firewall_subnet_prefix
  bastion_subnet_prefix   = var.hub_vnet_config.bastion_subnet_prefix

  providers = {
    azurerm = azurerm.connectivity
  }
}

module "spoke_networking" {
  source     = "./modules/networking"
  depends_on = [module.hub_networking]

  mode                     = "spoke"
  location                 = var.location
  address_space            = var.spoke_vnet_config.address_space
  workload_subnet_prefix   = var.spoke_vnet_config.workload_subnet_prefix
  data_subnet_prefix       = var.spoke_vnet_config.data_subnet_prefix
  appgw_subnet_prefix      = var.spoke_vnet_config.appgw_subnet_prefix
  hub_vnet_id              = module.hub_networking.vnet_id
  hub_firewall_private_ip  = module.hub_networking.firewall_private_ip

  vnet_name                  = format("%s-%s-spoke-vnet", var.client_name, var.environment)
  resource_group_name        = local.rg_spoke_networking
  log_analytics_workspace_id = module.monitoring.log_analytics_workspace_id

  providers = {
    azurerm = azurerm.workload
  }
}

# -----------------------------------------------------------------------------
# Workload Identity Module: Scoped Role Assignments
# -----------------------------------------------------------------------------
module "identity" {
  source     = "./modules/identity"
  depends_on = [module.spoke_networking]

  client_name         = var.client_name
  environment         = var.environment
  management_group_id = module.governance.management_group_id
  spoke_vnet_id       = module.spoke_networking.vnet_id

  providers = {
    azurerm = azurerm.workload
    azuread = azuread
  }
}
