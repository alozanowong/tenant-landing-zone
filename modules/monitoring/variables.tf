###############################################################################
# modules/monitoring/variables.tf
###############################################################################

variable "resource_group_name" {
  type        = string
  description = "Resource group for monitoring resources."
}

variable "location" {
  type        = string
  description = "Azure region."
}

variable "log_analytics_name" {
  type        = string
  description = "Name of the Log Analytics Workspace."
}

variable "retention_days" {
  type        = number
  description = "Log retention in days (30–730)."
  default     = 90
}

variable "client_subscription_id" {
  type        = string
  description = "Client subscription ID for Defender for Cloud workspace association."
}

variable "enable_defender" {
  type        = bool
  description = "Enable Defender for Cloud Standard tier."
  default     = true
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to all monitoring resources."
  default     = {}
}
