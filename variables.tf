###############################################################################
# variables.tf
# MSP Azure Landing Zone — Root Variable Definitions
# All variables are strongly typed with explicit validation blocks.
###############################################################################

###############################################################################
# IDENTITY & TENANT
###############################################################################

variable "tenant_id" {
  type        = string
  description = "Azure Active Directory Tenant ID shared across all MSP-managed subscriptions."

  validation {
    condition     = can(regex("^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$", var.tenant_id))
    error_message = "tenant_id must be a valid GUID (xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx)."
  }
}

variable "hub_subscription_id" {
  type        = string
  description = "Subscription ID for the Hub/Connectivity subscription hosting shared network resources (VPN/ExpressRoute, Azure Firewall, Bastion)."

  validation {
    condition     = can(regex("^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$", var.hub_subscription_id))
    error_message = "hub_subscription_id must be a valid GUID."
  }
}

variable "management_subscription_id" {
  type        = string
  description = "Subscription ID for the Management subscription hosting Log Analytics, Azure Monitor, Security Center, and policy artifacts."

  validation {
    condition     = can(regex("^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$", var.management_subscription_id))
    error_message = "management_subscription_id must be a valid GUID."
  }
}

variable "client_subscription_id" {
  type        = string
  description = "Subscription ID for the target client workload (Spoke) subscription being vended."

  validation {
    condition     = can(regex("^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$", var.client_subscription_id))
    error_message = "client_subscription_id must be a valid GUID."
  }
}

###############################################################################
# CLIENT METADATA
###############################################################################

variable "client_name" {
  type        = string
  description = "Short alphanumeric slug for the client (e.g., 'acmecorp', 'fabrikam'). Used in resource naming and tagging. No spaces or special characters."

  validation {
    condition     = can(regex("^[a-z0-9-]{3,24}$", var.client_name))
    error_message = "client_name must be 3–24 lowercase alphanumeric characters or hyphens."
  }
}

variable "client_display_name" {
  type        = string
  description = "Human-readable client name used in Management Group display names and tagging (e.g., 'Acme Corporation')."
}

variable "environment" {
  type        = string
  description = "Deployment environment tier. Controls resource sizing, redundancy settings, and policy enforcement modes."

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment must be one of: dev, staging, prod."
  }
}

variable "owner_email" {
  type        = string
  description = "Email address of the primary technical owner for this client landing zone. Used in mandatory resource tags."

  validation {
    condition     = can(regex("^[^@]+@[^@]+\\.[^@]+$", var.owner_email))
    error_message = "owner_email must be a valid email address."
  }
}

variable "cost_center" {
  type        = string
  description = "Client billing cost center code. Applied as a mandatory tag to all resource groups."
}

###############################################################################
# REGIONAL CONFIGURATION
###############################################################################

variable "location" {
  type        = string
  description = "Primary Azure region for all client resources (e.g., 'eastus2'). Must be in the MSP-approved region list enforced by Azure Policy."
  default     = "eastus2"

  validation {
    condition = contains([
      "eastus", "eastus2", "westus2", "westus3",
      "centralus", "northcentralus", "southcentralus",
      "westeurope", "northeurope", "uksouth", "ukwest",
      "australiaeast", "southeastasia"
    ], var.location)
    error_message = "location must be an MSP-approved Azure region."
  }
}

###############################################################################
# NETWORKING — HUB
###############################################################################

variable "hub_vnet_config" {
  type = object({
    address_space            = list(string)
    firewall_subnet_prefix   = string
    bastion_subnet_prefix    = string
    gateway_subnet_prefix    = string
    management_subnet_prefix = string
  })
  description = <<-EOT
    CIDR configuration for the Hub Virtual Network.
    - address_space: Overall VNet CIDR block(s) — typically a /22 from the MSP supernet.
    - firewall_subnet_prefix: Must be named 'AzureFirewallSubnet', minimum /26.
    - bastion_subnet_prefix: Must be named 'AzureBastionSubnet', minimum /27.
    - gateway_subnet_prefix: Must be named 'GatewaySubnet', minimum /27.
    - management_subnet_prefix: Jump/management subnet, minimum /28.
  EOT
  default = {
    address_space            = ["10.0.0.0/22"]
    firewall_subnet_prefix   = "10.0.0.0/26"
    bastion_subnet_prefix    = "10.0.0.64/27"
    gateway_subnet_prefix    = "10.0.0.96/27"
    management_subnet_prefix = "10.0.0.128/28"
  }

  validation {
    condition     = can(cidrhost(var.hub_vnet_config.firewall_subnet_prefix, 0))
    error_message = "hub_vnet_config.firewall_subnet_prefix must be a valid CIDR block."
  }
}

###############################################################################
# NETWORKING — SPOKE (Client)
###############################################################################

variable "spoke_vnet_config" {
  type = object({
    address_space          = list(string)
    workload_subnet_prefix = string
    data_subnet_prefix     = string
    appgw_subnet_prefix    = string
  })
  description = <<-EOT
    CIDR configuration for the client Spoke Virtual Network.
    - address_space: Overall VNet CIDR — allocated from the MSP IP plan, non-overlapping.
    - workload_subnet_prefix: General application/compute workloads.
    - data_subnet_prefix: Database and storage tier — NSG restricts inbound to workload subnet only.
    - appgw_subnet_prefix: Azure Application Gateway v2 subnet, minimum /24 per Microsoft requirement.
  EOT

  validation {
    condition     = can(cidrhost(var.spoke_vnet_config.address_space[0], 0))
    error_message = "spoke_vnet_config.address_space must contain valid CIDR blocks."
  }
}

###############################################################################
# GOVERNANCE
###############################################################################

variable "management_group_parent_id" {
  type        = string
  description = "ID of the parent Management Group under which the client's Management Group will be created. Typically the MSP's 'Clients' MG (e.g., '/providers/Microsoft.Management/managementGroups/mg-msp-clients')."
}

variable "policy_enforcement_mode" {
  type        = string
  description = "Azure Policy assignment enforcement mode. Use 'DoNotEnforce' in dev/staging for audit-only; 'Default' (enforced) in production."
  default     = "Default"

  validation {
    condition     = contains(["Default", "DoNotEnforce"], var.policy_enforcement_mode)
    error_message = "policy_enforcement_mode must be 'Default' or 'DoNotEnforce'."
  }
}

variable "allowed_vm_skus" {
  type        = list(string)
  description = "List of permitted Azure VM SKUs for this client environment, enforced via Azure Policy. Restrict to cost-appropriate tiers per client SLA."
  default = [
    "Standard_B2s", "Standard_B4ms",
    "Standard_D2s_v5", "Standard_D4s_v5", "Standard_D8s_v5",
    "Standard_E4s_v5", "Standard_E8s_v5"
  ]
}

###############################################################################
# MONITORING
###############################################################################

variable "log_analytics_retention_days" {
  type        = number
  description = "Log Analytics Workspace data retention in days. Minimum 30 for basic compliance; 90+ recommended for SOC 2 / ISO 27001."
  default     = 90

  validation {
    condition     = var.log_analytics_retention_days >= 30 && var.log_analytics_retention_days <= 730
    error_message = "log_analytics_retention_days must be between 30 and 730."
  }
}

variable "enable_defender_for_cloud" {
  type        = bool
  description = "Enable Microsoft Defender for Cloud (Standard tier) on the client subscription. Strongly recommended for production environments."
  default     = true
}

###############################################################################
# TAGGING
###############################################################################

variable "global_tags" {
  type        = map(string)
  description = <<-EOT
    Mandatory baseline tags applied to all resource groups. These are merged with
    module-level tags. Required keys: ManagedBy, Environment, CostCenter, Owner.
    Additional client-specific tags may be added freely.
  EOT
  default     = {}
}

variable "deploy_timestamp" {
  type        = string
  description = <<-EOT
    ISO 8601 timestamp of the deployment, injected by the CI pipeline to populate
    the LastModified tag. Using a pipeline variable instead of timestamp() prevents
    a perpetual diff on every terraform plan.
    In CI: set via TF_VAR_deploy_timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ)
    For local runs the default value is used and no diff is produced.
  EOT
  default     = "local-run"
}
