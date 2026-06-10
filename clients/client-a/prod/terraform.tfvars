###############################################################################
# clients/client-a/prod/terraform.tfvars
# MSP ALZ — Client A Production Landing Zone
# Populated by MSP onboarding engineer. All subscription IDs come from the
# MSP subscription vending pipeline output.
###############################################################################

# ── Identity & Tenant ─────────────────────────────────────────────────────────
tenant_id                  = "00000000-0000-0000-0000-000000000001"  # Contoso MSP Tenant
hub_subscription_id        = "11111111-0000-0000-0000-000000000001"  # MSP Hub Subscription
management_subscription_id = "22222222-0000-0000-0000-000000000001"  # MSP Management Subscription
client_subscription_id     = "33333333-0000-0000-0000-000000000001"  # Client A Production

# ── Client Metadata ───────────────────────────────────────────────────────────
client_name         = "acmecorp"
client_display_name = "Acme Corporation"
environment         = "prod"
owner_email         = "platform@acmecorp.com"
cost_center         = "CC-ACME-001"

# ── Regional Configuration ────────────────────────────────────────────────────
primary_location   = "eastus2"
secondary_location = "eastus"

# ── Hub Networking ────────────────────────────────────────────────────────────
hub_vnet_config = {
  address_space            = ["10.0.0.0/22"]
  firewall_subnet_prefix   = "10.0.0.0/26"
  bastion_subnet_prefix    = "10.0.0.64/27"
  gateway_subnet_prefix    = "10.0.0.96/27"
  management_subnet_prefix = "10.0.0.128/28"
}

# ── Spoke Networking — Non-overlapping with Hub ───────────────────────────────
spoke_vnet_config = {
  address_space          = ["10.1.0.0/22"]
  workload_subnet_prefix = "10.1.0.0/24"
  data_subnet_prefix     = "10.1.1.0/25"
  appgw_subnet_prefix    = "10.1.2.0/24"
}

# ── Governance ────────────────────────────────────────────────────────────────
management_group_parent_id = "/providers/Microsoft.Management/managementGroups/mg-msp-clients"
policy_enforcement_mode    = "Default"  # Enforced in production

allowed_vm_skus = [
  "Standard_D4s_v5",
  "Standard_D8s_v5",
  "Standard_E4s_v5",
  "Standard_E8s_v5"
]

# ── Monitoring ────────────────────────────────────────────────────────────────
log_analytics_retention_days = 90
enable_defender_for_cloud    = true

# ── Baseline Tags ─────────────────────────────────────────────────────────────
global_tags = {
  Client      = "Acme Corporation"
  Contract    = "MSP-ACME-2024"
  Tier        = "Premium"
  Criticality = "High"
}
