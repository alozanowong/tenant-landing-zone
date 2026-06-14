###############################################################################
# modules/identity/outputs.tf
###############################################################################

output "workload_owners_group_id" {
  value       = azuread_group.client_workload_owners.id
  description = "Object ID of the workload owners Azure AD group."
}

output "workload_contributors_group_id" {
  value       = azuread_group.client_workload_contributors.id
  description = "Object ID of the workload contributors Azure AD group."
}

output "network_readers_group_id" {
  value       = azuread_group.client_network_readers.id
  description = "Object ID of the network readers Azure AD group."
}
