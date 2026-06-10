###############################################################################
# outputs.tf
# MSP Azure Landing Zone — Root Module Outputs
###############################################################################

output "client_management_group_id" {
  value       = module.governance.management_group_id
  description = "Full resource ID of the provisioned client Management Group."
}

output "hub_vnet_id" {
  value       = module.hub_networking.vnet_id
  description = "Resource ID of the Hub Virtual Network."
}

output "spoke_vnet_id" {
  value       = module.spoke_networking.vnet_id
  description = "Resource ID of the client Spoke Virtual Network."
}

output "hub_firewall_private_ip" {
  value       = module.hub_networking.firewall_private_ip
  description = "Private IP of the Azure Firewall — used as UDR next-hop for all spoke traffic."
}

output "log_analytics_workspace_id" {
  value       = module.monitoring.log_analytics_workspace_id
  description = "Resource ID of the central Log Analytics Workspace."
}

output "log_analytics_customer_id" {
  value       = module.monitoring.log_analytics_customer_id
  description = "Log Analytics Workspace GUID for agent onboarding."
}

output "workload_subnet_id" {
  value       = module.spoke_networking.workload_subnet_id
  description = "Resource ID of the spoke workload subnet — use for VM/AKS/VMSS deployments."
}

output "data_subnet_id" {
  value       = module.spoke_networking.data_subnet_id
  description = "Resource ID of the spoke data subnet — use for Azure SQL MI, PostgreSQL Flexible Server."
}

output "appgw_subnet_id" {
  value       = module.spoke_networking.appgw_subnet_id
  description = "Resource ID of the Application Gateway subnet."
}
