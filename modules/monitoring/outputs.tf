###############################################################################
# modules/monitoring/outputs.tf
###############################################################################

output "log_analytics_workspace_id" {
  value       = azurerm_log_analytics_workspace.central.id
  description = "Resource ID of the central Log Analytics Workspace."
}

output "log_analytics_workspace_key" {
  value       = azurerm_log_analytics_workspace.central.primary_shared_key
  sensitive   = true
  description = "Primary shared key of the Log Analytics Workspace. Sensitive — store in Key Vault."
}

output "log_analytics_customer_id" {
  value       = azurerm_log_analytics_workspace.central.workspace_id
  description = "Log Analytics Workspace GUID (Customer ID) used for agent onboarding."
}
