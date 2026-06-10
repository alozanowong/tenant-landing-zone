###############################################################################
# modules/networking/outputs.tf
###############################################################################

output "vnet_id" {
  value       = var.mode == "hub" ? azurerm_virtual_network.hub[0].id : azurerm_virtual_network.spoke[0].id
  description = "Resource ID of the created Virtual Network."
}

output "vnet_name" {
  value       = var.mode == "hub" ? azurerm_virtual_network.hub[0].name : azurerm_virtual_network.spoke[0].name
  description = "Name of the created Virtual Network."
}

output "firewall_private_ip" {
  value       = var.mode == "hub" ? azurerm_firewall.hub[0].ip_configuration[0].private_ip_address : null
  description = "[Hub only] Private IP of the Azure Firewall. Used as UDR next-hop in Spoke modules."
}

output "firewall_id" {
  value       = var.mode == "hub" ? azurerm_firewall.hub[0].id : null
  description = "[Hub only] Resource ID of the Azure Firewall."
}

output "bastion_id" {
  value       = var.mode == "hub" ? azurerm_bastion_host.hub[0].id : null
  description = "[Hub only] Resource ID of the Azure Bastion host."
}

output "resource_group_name" {
  value       = azurerm_resource_group.networking.name
  description = "Name of the networking resource group."
}

output "workload_subnet_id" {
  value       = var.mode == "spoke" ? azurerm_subnet.workload[0].id : null
  description = "[Spoke only] Resource ID of the workload subnet."
}

output "data_subnet_id" {
  value       = var.mode == "spoke" ? azurerm_subnet.data[0].id : null
  description = "[Spoke only] Resource ID of the data subnet."
}

output "appgw_subnet_id" {
  value       = var.mode == "spoke" ? azurerm_subnet.appgw[0].id : null
  description = "[Spoke only] Resource ID of the Application Gateway subnet."
}
