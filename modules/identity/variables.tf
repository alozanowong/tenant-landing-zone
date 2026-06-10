###############################################################################
# modules/identity/variables.tf
###############################################################################

variable "client_name" {
  type        = string
  description = "Short alphanumeric client slug for naming groups."
}

variable "environment" {
  type        = string
  description = "Deployment environment (dev, staging, prod)."
}

variable "client_subscription_id" {
  type        = string
  description = "Client workload subscription ID for scoped role assignments."
}

variable "management_group_id" {
  type        = string
  description = "Full resource ID of the client Management Group."
}

variable "spoke_vnet_id" {
  type        = string
  description = "Resource ID of the client Spoke VNet for network-scoped RBAC."
}

variable "tags" {
  type        = map(string)
  description = "Tags — passed through for any taggable identity resources."
  default     = {}
}
