###############################################################################
# modules/governance/variables.tf
###############################################################################


variable "client_display_name" {
  type        = string
  description = "Human-readable client name for Management Group display names."
}

variable "environment" {
  type        = string
  description = "Deployment environment (dev, staging, prod)."
}

variable "management_group_name" {
  type        = string
  description = "Name (ID) for the client Management Group resource."
}

variable "management_group_parent_id" {
  type        = string
  description = "Full resource ID of the parent Management Group."
}

variable "client_subscription_id" {
  type        = string
  description = "Subscription ID to associate with the client Management Group."
}

variable "primary_location" {
  type        = string
  description = "Primary Azure region — used in policy parameter values."
}

variable "secondary_location" {
  type        = string
  description = "Secondary/paired Azure region — added to allowed locations policy."
}

variable "policy_enforcement_mode" {
  type        = string
  description = "Azure Policy assignment enforcement mode ('Default' or 'DoNotEnforce')."
  default     = "Default"
}

variable "allowed_vm_skus" {
  type        = list(string)
  description = "List of permitted VM SKUs enforced via policy."
}

variable "log_analytics_workspace_id" {
  type        = string
  description = "Resource ID of the Log Analytics Workspace for Management Group diagnostic settings."
}

variable "msp_platform_team_group_id" {
  type        = string
  description = "Object ID of the MSP Platform Engineering Azure AD group. Assigned Contributor role on client MG."
}

variable "msp_security_team_group_id" {
  type        = string
  description = "Object ID of the MSP Security Operations Azure AD group. Assigned Security Reader role."
}

variable "client_admin_group_id" {
  type        = string
  description = "Object ID of the client's Azure AD admin group. Assigned Reader role for visibility."
}

