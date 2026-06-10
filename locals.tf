locals {
  # Dynamic Azure resource naming prefix based on target workspace context
  azure_prefix = "tlz-az-${var.client_name}-${var.environment}"

  # Core metadata tags applied universally to all cloud resources[cite: 1]
  base_tags = {
    ManagedBy         = "Terraform"[cite: 1]
    PlatformEngine    = "tenant-landing-zone"
    CloudProvider     = "Azure"
    ClientName        = var.client_name[cite: 1]
    Environment       = var.environment[cite: 1]
    FactoryDeployment = var.deployment_timestamp
  }
}
