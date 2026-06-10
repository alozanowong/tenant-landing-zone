###############################################################################
# modules/governance/main.tf
# MSP ALZ — Governance Module
# Provisions:
#   1. Management Group hierarchy for the client
#   2. Custom Azure Policy definitions (region restriction, tag enforcement, no public IPs)
#   3. Policy Initiative (Policy Set) bundling all baseline policies
#   4. Policy Initiative assignment scoped to the client Management Group
#   5. Diagnostic settings forwarding MG activity to Log Analytics
###############################################################################

###############################################################################
# MANAGEMENT GROUP
###############################################################################

resource "azurerm_management_group" "client" {
  name         = var.management_group_name
  display_name = "${var.client_display_name} — ${upper(var.environment)}"
  parent_management_group_id = var.management_group_parent_id
}

resource "azurerm_management_group_subscription_association" "client" {
  management_group_id = azurerm_management_group.client.id
  subscription_id     = "/subscriptions/${var.client_subscription_id}"
}

###############################################################################
# CUSTOM POLICY DEFINITION: Allowed Locations
# Prevents resource deployment outside MSP-approved regions.
###############################################################################

resource "azurerm_policy_definition" "allowed_locations" {
  name         = "pol-msp-allowed-locations"
  policy_type  = "Custom"
  mode         = "Indexed"
  display_name = "[MSP] Allowed Azure Regions"
  description  = "Restricts resource deployment to MSP-approved Azure regions only. Resources in unapproved regions will be denied at ARM API level."

  management_group_id = azurerm_management_group.client.id

  metadata = jsonencode({
    category = "MSP Governance"
    version  = "1.0.0"
  })

  policy_rule = jsonencode({
    if = {
      not = {
        field = "location"
        in    = "[parameters('allowedLocations')]"
      }
    }
    then = {
      effect = "[parameters('effect')]"
    }
  })

  parameters = jsonencode({
    allowedLocations = {
      type = "Array"
      metadata = {
        displayName = "Allowed Locations"
        description = "List of Azure regions where resources may be deployed."
        strongType  = "location"
      }
    }
    effect = {
      type = "String"
      metadata = {
        displayName = "Effect"
        description = "Deny blocks deployment; Audit logs without blocking."
      }
      allowedValues = ["Deny", "Audit", "Disabled"]
      defaultValue  = "Deny"
    }
  })
}

###############################################################################
# CUSTOM POLICY DEFINITION: Require Mandatory Tags on Resource Groups
###############################################################################

resource "azurerm_policy_definition" "require_tags" {
  name         = "pol-msp-require-rg-tags"
  policy_type  = "Custom"
  mode         = "All"
  display_name = "[MSP] Require Mandatory Tags on Resource Groups"
  description  = "Enforces that all resource groups carry the mandatory MSP tags: Environment, CostCenter, Owner, ManagedBy."

  management_group_id = azurerm_management_group.client.id

  metadata = jsonencode({
    category = "MSP Governance"
    version  = "1.0.0"
  })

  policy_rule = jsonencode({
    if = {
      allOf = [
        {
          field  = "type"
          equals = "Microsoft.Resources/subscriptions/resourceGroups"
        },
        {
          anyOf = [
            { field = "tags['Environment']", exists = "false" },
            { field = "tags['CostCenter']",  exists = "false" },
            { field = "tags['Owner']",        exists = "false" },
            { field = "tags['ManagedBy']",    exists = "false" }
          ]
        }
      ]
    }
    then = {
      effect = "[parameters('effect')]"
    }
  })

  parameters = jsonencode({
    effect = {
      type         = "String"
      defaultValue = "Deny"
      allowedValues = ["Deny", "Audit", "Disabled"]
      metadata = {
        displayName = "Effect"
      }
    }
  })
}

###############################################################################
# CUSTOM POLICY DEFINITION: Deny Public IP Addresses
# Prevents accidental direct internet exposure of workload VMs.
###############################################################################

resource "azurerm_policy_definition" "deny_public_ip" {
  name         = "pol-msp-deny-public-ip"
  policy_type  = "Custom"
  mode         = "Indexed"
  display_name = "[MSP] Deny Public IP Address Creation"
  description  = "Blocks creation of standalone Public IP addresses. All internet ingress must route through Azure Firewall or Application Gateway in the Hub. Exempt resource IDs (Firewall, Bastion PIPs) should be added to the notScopes at assignment time."

  management_group_id = azurerm_management_group.client.id

  metadata = jsonencode({
    category = "MSP Governance"
    version  = "1.0.0"
  })

  policy_rule = jsonencode({
    if = {
      field  = "type"
      equals = "Microsoft.Network/publicIPAddresses"
    }
    then = {
      effect = "[parameters('effect')]"
    }
  })

  parameters = jsonencode({
    effect = {
      type         = "String"
      defaultValue = "Deny"
      allowedValues = ["Deny", "Audit", "Disabled"]
      metadata = {
        displayName = "Effect"
      }
    }
  })
}

###############################################################################
# CUSTOM POLICY DEFINITION: Allowed VM SKUs
###############################################################################

resource "azurerm_policy_definition" "allowed_vm_skus" {
  name         = "pol-msp-allowed-vm-skus"
  policy_type  = "Custom"
  mode         = "Indexed"
  display_name = "[MSP] Allowed Virtual Machine SKUs"
  description  = "Restricts VM deployments to a pre-approved list of SKUs to control cost and ensure client SLA alignment."

  management_group_id = azurerm_management_group.client.id

  metadata = jsonencode({
    category = "MSP Governance"
    version  = "1.0.0"
  })

  policy_rule = jsonencode({
    if = {
      allOf = [
        {
          field  = "type"
          equals = "Microsoft.Compute/virtualMachines"
        },
        {
          not = {
            field = "Microsoft.Compute/virtualMachines/sku.name"
            in    = "[parameters('allowedSkus')]"
          }
        }
      ]
    }
    then = {
      effect = "[parameters('effect')]"
    }
  })

  parameters = jsonencode({
    allowedSkus = {
      type = "Array"
      metadata = {
        displayName = "Allowed VM SKUs"
        description = "List of permitted VM size SKUs."
        strongType  = "VMSKUs"
      }
    }
    effect = {
      type         = "String"
      defaultValue = "Deny"
      allowedValues = ["Deny", "Audit", "Disabled"]
      metadata = {
        displayName = "Effect"
      }
    }
  })
}

###############################################################################
# CUSTOM POLICY DEFINITION: DeployIfNotExists — Enable Defender for Cloud
###############################################################################

resource "azurerm_policy_definition" "enable_defender" {
  name         = "pol-msp-enable-defender"
  policy_type  = "Custom"
  mode         = "All"
  display_name = "[MSP] Enable Microsoft Defender for Cloud — Standard"
  description  = "Ensures Microsoft Defender for Cloud Standard tier is enabled for key workload types on the client subscription."

  management_group_id = azurerm_management_group.client.id

  metadata = jsonencode({
    category = "MSP Governance"
    version  = "1.0.0"
  })

  policy_rule = jsonencode({
    if = {
      field  = "type"
      equals = "Microsoft.Resources/subscriptions"
    }
    then = {
      effect = "DeployIfNotExists"
      details = {
        type = "Microsoft.Security/pricings"
        name = "VirtualMachines"
        existenceCondition = {
          field  = "Microsoft.Security/pricings/pricingTier"
          equals = "Standard"
        }
        roleDefinitionIds = [
          "/providers/Microsoft.Authorization/roleDefinitions/fb1c8493-542b-48eb-b624-b4c8fea62acd"
        ]
        deployment = {
          properties = {
            mode     = "incremental"
            template = {
              "$schema"      = "https://schema.management.azure.com/schemas/2018-05-01/subscriptionDeploymentTemplate.json#"
              contentVersion = "1.0.0.0"
              resources = [
                {
                  type       = "Microsoft.Security/pricings"
                  apiVersion = "2023-01-01"
                  name       = "VirtualMachines"
                  properties = { pricingTier = "Standard" }
                },
                {
                  type       = "Microsoft.Security/pricings"
                  apiVersion = "2023-01-01"
                  name       = "SqlServers"
                  properties = { pricingTier = "Standard" }
                },
                {
                  type       = "Microsoft.Security/pricings"
                  apiVersion = "2023-01-01"
                  name       = "AppServices"
                  properties = { pricingTier = "Standard" }
                }
              ]
            }
          }
        }
      }
    }
  })

  parameters = jsonencode({})
}

###############################################################################
# POLICY INITIATIVE (SET) — MSP Baseline Guardrails
# Bundles all custom policies into a single assignable initiative.
###############################################################################

resource "azurerm_policy_set_definition" "msp_baseline" {
  name         = "policyset-msp-baseline-guardrails"
  policy_type  = "Custom"
  display_name = "[MSP] Baseline Landing Zone Guardrails"
  description  = "Bundled MSP governance initiative enforcing region restrictions, mandatory tagging, network security guardrails, approved VM SKUs, and Defender for Cloud."

  management_group_id = azurerm_management_group.client.id

  metadata = jsonencode({
    category = "MSP Governance"
    version  = "1.0.0"
  })

  # Policy 1: Allowed Locations
  policy_definition_reference {
    policy_definition_id = azurerm_policy_definition.allowed_locations.id
    reference_id         = "allowed-locations"
    parameter_values = jsonencode({
      allowedLocations = { value = [var.primary_location, var.secondary_location] }
      effect           = { value = var.policy_enforcement_mode == "DoNotEnforce" ? "Audit" : "Deny" }
    })
  }

  # Policy 2: Require Tags
  policy_definition_reference {
    policy_definition_id = azurerm_policy_definition.require_tags.id
    reference_id         = "require-rg-tags"
    parameter_values = jsonencode({
      effect = { value = var.policy_enforcement_mode == "DoNotEnforce" ? "Audit" : "Deny" }
    })
  }

  # Policy 3: Deny Public IP
  policy_definition_reference {
    policy_definition_id = azurerm_policy_definition.deny_public_ip.id
    reference_id         = "deny-public-ip"
    parameter_values = jsonencode({
      effect = { value = var.policy_enforcement_mode == "DoNotEnforce" ? "Audit" : "Deny" }
    })
  }

  # Policy 4: Allowed VM SKUs
  policy_definition_reference {
    policy_definition_id = azurerm_policy_definition.allowed_vm_skus.id
    reference_id         = "allowed-vm-skus"
    parameter_values = jsonencode({
      allowedSkus = { value = var.allowed_vm_skus }
      effect      = { value = var.policy_enforcement_mode == "DoNotEnforce" ? "Audit" : "Deny" }
    })
  }

  # Policy 5: Enable Defender
  policy_definition_reference {
    policy_definition_id = azurerm_policy_definition.enable_defender.id
    reference_id         = "enable-defender"
  }

  depends_on = [
    azurerm_policy_definition.allowed_locations,
    azurerm_policy_definition.require_tags,
    azurerm_policy_definition.deny_public_ip,
    azurerm_policy_definition.allowed_vm_skus,
    azurerm_policy_definition.enable_defender
  ]
}

###############################################################################
# POLICY ASSIGNMENT — Assign Initiative to Client Management Group
###############################################################################

resource "azurerm_management_group_policy_assignment" "msp_baseline" {
  name                 = "assign-msp-baseline"
  display_name         = "[MSP] Baseline Guardrails — ${var.client_display_name}"
  policy_definition_id = azurerm_policy_set_definition.msp_baseline.id
  management_group_id  = azurerm_management_group.client.id
  enforcement_mode     = var.policy_enforcement_mode
  description          = "Assigns the MSP Baseline Guardrail initiative to the ${var.client_display_name} Management Group. Enforced in production; audit-only in dev/staging."

  # System-assigned managed identity required for DeployIfNotExists policies
  identity {
    type = "SystemAssigned"
  }

  location = var.primary_location

  not_scopes = []  # Populate with Hub subscription IDs to exempt Firewall/Bastion PIPs

  depends_on = [azurerm_policy_set_definition.msp_baseline]
}

###############################################################################
# RBAC — Built-in Role Assignments on Client Management Group
###############################################################################

# MSP Platform Team — Contributor on client MG (scoped, not Owner)
resource "azurerm_role_assignment" "msp_platform_contributor" {
  scope                = azurerm_management_group.client.id
  role_definition_name = "Contributor"
  principal_id         = var.msp_platform_team_group_id
  description          = "MSP Platform Engineering team — manages infrastructure deployments for client."
}

# MSP Security Team — Security Reader (read-only)
resource "azurerm_role_assignment" "msp_security_reader" {
  scope                = azurerm_management_group.client.id
  role_definition_name = "Security Reader"
  principal_id         = var.msp_security_team_group_id
  description          = "MSP Security Operations — read access to Defender and compliance posture."
}

# Client Admin Group — Reader at MG level (cannot modify infrastructure)
resource "azurerm_role_assignment" "client_reader" {
  scope                = azurerm_management_group.client.id
  role_definition_name = "Reader"
  principal_id         = var.client_admin_group_id
  description          = "Client administrators — read-only visibility into their landing zone."
}

# Policy Remediation — Required for DeployIfNotExists policies
resource "azurerm_role_assignment" "policy_remediation" {
  scope                = "/subscriptions/${var.client_subscription_id}"
  role_definition_name = "Security Admin"
  principal_id         = azurerm_management_group_policy_assignment.msp_baseline.identity[0].principal_id
  description          = "Allows Policy managed identity to remediate non-compliant Defender settings."

  depends_on = [azurerm_management_group_policy_assignment.msp_baseline]
}
