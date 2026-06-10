###############################################################################
# modules/governance/outputs.tf
###############################################################################

output "management_group_id" {
  value       = azurerm_management_group.client.id
  description = "Full resource ID of the client Management Group."
}

output "management_group_name" {
  value       = azurerm_management_group.client.name
  description = "Name (short ID) of the client Management Group."
}

output "policy_assignment_id" {
  value       = azurerm_management_group_policy_assignment.msp_baseline.id
  description = "Resource ID of the MSP Baseline policy initiative assignment."
}

output "policy_assignment_identity_principal_id" {
  value       = azurerm_management_group_policy_assignment.msp_baseline.identity[0].principal_id
  description = "Object ID of the system-assigned managed identity for policy remediation tasks."
}
