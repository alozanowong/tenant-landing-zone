###############################################################################
# modules/networking/variables.tf
###############################################################################

variable "mode" {
  type        = string
  description = "Networking mode: 'hub' deploys Hub VNet with Firewall and Bastion; 'spoke' deploys client Spoke VNet with peering."
  validation {
    condition     = contains(["hub", "spoke"], var.mode)
    error_message = "mode must be 'hub' or 'spoke'."
  }
}

variable "resource_group_name" {
  type        = string
  description = "Name of the resource group to create networking resources in."
}

variable "location" {
  type        = string
  description = "Azure region for all networking resources."
}

variable "vnet_name" {
  type        = string
  description = "Name of the Virtual Network to create."
}

variable "address_space" {
  type        = list(string)
  description = "CIDR address space(s) for the VNet."
}

variable "log_analytics_workspace_id" {
  type        = string
  description = "Resource ID of the Log Analytics Workspace for diagnostic settings."
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to all resources in this module."
  default     = {}
}

# Hub-only variables
variable "firewall_subnet_prefix" {
  type        = string
  description = "[Hub only] CIDR prefix for AzureFirewallSubnet (minimum /26)."
  default     = ""
}

variable "bastion_subnet_prefix" {
  type        = string
  description = "[Hub only] CIDR prefix for AzureBastionSubnet (minimum /27)."
  default     = ""
}

variable "gateway_subnet_prefix" {
  type        = string
  description = "[Hub only] CIDR prefix for GatewaySubnet (minimum /27)."
  default     = ""
}

variable "management_subnet_prefix" {
  type        = string
  description = "[Hub only] CIDR prefix for the management/jump subnet."
  default     = ""
}

variable "firewall_name" {
  type        = string
  description = "[Hub only] Name for the Azure Firewall resource."
  default     = ""
}

variable "firewall_pip_name" {
  type        = string
  description = "[Hub only] Name for the Azure Firewall Public IP."
  default     = ""
}

variable "bastion_name" {
  type        = string
  description = "[Hub only] Name for the Azure Bastion resource."
  default     = ""
}

variable "bastion_pip_name" {
  type        = string
  description = "[Hub only] Name for the Azure Bastion Public IP."
  default     = ""
}

# Spoke-only variables
variable "workload_subnet_prefix" {
  type        = string
  description = "[Spoke only] CIDR prefix for the workload/application subnet."
  default     = ""
}

variable "data_subnet_prefix" {
  type        = string
  description = "[Spoke only] CIDR prefix for the data/database subnet."
  default     = ""
}

variable "appgw_subnet_prefix" {
  type        = string
  description = "[Spoke only] CIDR prefix for the Application Gateway v2 subnet (minimum /24)."
  default     = ""
}

variable "hub_vnet_id" {
  type        = string
  description = "[Spoke only] Resource ID of the Hub VNet to peer with."
  default     = ""
}

variable "hub_firewall_private_ip" {
  type        = string
  description = "[Spoke only] Private IP address of the Azure Firewall in the Hub for UDR next-hop."
  default     = ""
}
