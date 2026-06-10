###############################################################################
# clients/client-a/dev/terraform.tfvars
# MSP ALZ — Client A Development Landing Zone
# Smaller CIDRs, relaxed VM SKUs, policies in audit (DoNotEnforce) mode.
###############################################################################

tenant_id                  = "00000000-0000-0000-0000-000000000001"
hub_subscription_id        = "11111111-0000-0000-0000-000000000001"
management_subscription_id = "22222222-0000-0000-0000-000000000001"
client_subscription_id     = "44444444-0000-0000-0000-000000000001"  # Client A Dev

client_name         = "acmecorp"
client_display_name = "Acme Corporation"
environment         = "dev"
owner_email         = "platform@acmecorp.com"
cost_center         = "CC-ACME-001-DEV"

primary_location   = "eastus2"
secondary_location = "eastus"

hub_vnet_config = {
  address_space            = ["10.10.0.0/22"]
  firewall_subnet_prefix   = "10.10.0.0/26"
  bastion_subnet_prefix    = "10.10.0.64/27"
  gateway_subnet_prefix    = "10.10.0.96/27"
  management_subnet_prefix = "10.10.0.128/28"
}

spoke_vnet_config = {
  address_space          = ["10.11.0.0/22"]
  workload_subnet_prefix = "10.11.0.0/24"
  data_subnet_prefix     = "10.11.1.0/25"
  appgw_subnet_prefix    = "10.11.2.0/24"
}

management_group_parent_id = "/providers/Microsoft.Management/managementGroups/mg-msp-clients"
policy_enforcement_mode    = "DoNotEnforce"  # Audit-only in dev

allowed_vm_skus = [
  "Standard_B2s",
  "Standard_B4ms",
  "Standard_D2s_v5",
  "Standard_D4s_v5"
]

log_analytics_retention_days = 30
enable_defender_for_cloud    = false  # Cost optimization in dev

global_tags = {
  Client      = "Acme Corporation"
  Contract    = "MSP-ACME-2024"
  Tier        = "Standard"
  Criticality = "Low"
}
