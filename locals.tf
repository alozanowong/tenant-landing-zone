###############################################################################
# locals.tf
# MSP Azure Landing Zone — Computed Locals & Naming Convention
###############################################################################

locals {
  # tflint-ignore: terraform_unused_declarations
  ###########################################################################
  # Naming Convention: {prefix}-{client}-{env}-{resource_type}-{suffix}
  # Example: msp-acmecorp-prod-vnet-hub
  ###########################################################################
  name_prefix = "msp-${var.client_name}-${var.environment}"

  ###########################################################################
  # Mandatory Tag Baseline
  # Merged: global_tags (lowest precedence) + computed tags (highest)
  # Note: LastModified is injected by the pipeline via var.deploy_timestamp
  # to avoid the perpetual diff caused by timestamp().
  ###########################################################################
  mandatory_tags = merge(
    var.global_tags,
    {
      ManagedBy        = "MSP-Terraform"
      Environment      = var.environment
      CostCenter       = var.cost_center
      Owner            = var.owner_email
      Client           = var.client_display_name
      DeployedBy       = "terraform"
      TerraformVersion = ">=1.5"
      LastModified     = var.deploy_timestamp
    }
  )

  ###########################################################################
  # Resource Group Names
  ###########################################################################
  rg_hub_networking   = "${local.name_prefix}-rg-hub-network"
  rg_spoke_networking = "${local.name_prefix}-rg-spoke-network"
  rg_monitoring       = "${local.name_prefix}-rg-management" # Monitoring resources share management RG

  firewall_name     = "${local.name_prefix}-afw"
  firewall_pip_name = "${local.name_prefix}-pip-afw"
  bastion_name      = "${local.name_prefix}-bas"
  bastion_pip_name  = "${local.name_prefix}-pip-bas"

}

