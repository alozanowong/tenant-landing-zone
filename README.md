# MSP Azure Landing Zone — Multi-Tenant IaC Blueprint

[![Terraform](https://img.shields.io/badge/Terraform-≥1.5-623CE4?logo=terraform)](https://www.terraform.io)
[![AzureRM](https://img.shields.io/badge/AzureRM-≥3.90-0078D4?logo=microsoft-azure)](https://registry.terraform.io/providers/hashicorp/azurerm)
[![CI](https://github.com/your-org/msp-azure-landing-zone/actions/workflows/terraform-deploy.yml/badge.svg)](https://github.com/your-org/msp-azure-landing-zone/actions)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

A production-grade Terraform repository enabling Managed Service Providers (MSPs) to rapidly vend standardized, secure, multi-tenant Azure Landing Zones aligned to the **Microsoft Cloud Adoption Framework (CAF)**. Each client receives an isolated Hub-and-Spoke topology, enterprise governance guardrails, and a dedicated Management Group hierarchy — deployed repeatably through a modular, DRY configuration pattern.

---

## Table of Contents

- [Architecture Overview](#architecture-overview)
- [Repository Structure](#repository-structure)
- [Design Decisions](#design-decisions)
- [Prerequisites](#prerequisites)
- [Onboarding a New Client](#onboarding-a-new-client)
- [Deployment Steps](#deployment-steps)
- [Module Reference](#module-reference)
- [Governance Guardrails](#governance-guardrails)
- [CI/CD Pipeline](#cicd-pipeline)
- [Security Posture](#security-posture)
- [Contributing](#contributing)

---

## Architecture Overview

```
MSP Tenant
│
├── Management Group: mg-msp-root
│   ├── mg-msp-platform          ← Hub, Management, Identity subscriptions
│   └── mg-msp-clients           ← Parent for all client MGs
│       ├── mg-acmecorp-prod     ← Client A Production
│       ├── mg-acmecorp-dev      ← Client A Development
│       └── mg-fabrikam-prod     ← Client B Production
│
│  ┌─────────────────────────────────────────────────────────┐
│  │  Hub Subscription (Connectivity)                        │
│  │  ┌─────────────────────────────────────────────────┐   │
│  │  │  Hub VNet  10.0.0.0/22                          │   │
│  │  │  ┌──────────────┐  ┌──────────────┐            │   │
│  │  │  │ Azure        │  │ Azure        │            │   │
│  │  │  │ Firewall     │  │ Bastion      │            │   │
│  │  │  │ /26          │  │ /27          │            │   │
│  │  │  └──────┬───────┘  └──────────────┘            │   │
│  │  └─────────┼───────────────────────────────────────┘   │
│  └────────────┼────────────────────────────────────────────┘
│               │ VNet Peering + UDR (0.0.0.0/0 → Firewall)
│  ┌────────────┼────────────────────────────────────────────┐
│  │  Client Subscription (Spoke)                │           │
│  │  ┌──────────────────────────────────────────┼───────┐  │
│  │  │  Spoke VNet  10.1.0.0/22                 │       │  │
│  │  │  ┌──────────────┐  ┌──────────────┐      │       │  │
│  │  │  │ Workload     │  │ Data         │      │       │  │
│  │  │  │ Subnet /24   │  │ Subnet /25   │      │       │  │
│  │  │  │ (NSG + UDR)  │  │ (Strict NSG) │      │       │  │
│  │  │  └──────────────┘  └──────────────┘      │       │  │
│  │  │  ┌──────────────┐                        │       │  │
│  │  │  │ AppGW        │                        │       │  │
│  │  │  │ Subnet /24   │                        │       │  │
│  │  │  └──────────────┘                        │       │  │
│  │  └──────────────────────────────────────────────────┘  │
│  └─────────────────────────────────────────────────────────┘
│
└── Management Subscription
    └── Log Analytics Workspace (central, all clients)
    └── Defender for Cloud (per-client workspace mapping)
```

All east-west and north-south traffic egresses through Azure Firewall in the Hub. Direct internet routes from spoke subnets are blocked via UDR and NSG deny rules. Bastion provides agentless RDP/SSH without exposing VMs to the internet.

---

## Repository Structure

```
msp-azure-landing-zone/
│
├── main.tf                          # Root orchestration — calls all modules
├── providers.tf                     # Multi-provider, multi-subscription config + backend
├── variables.tf                     # Strongly typed root variable definitions
├── locals.tf                        # Computed naming convention + tag merging
├── outputs.tf                       # Root outputs (VNet IDs, Firewall IP, LAW ID)
│
├── modules/
│   ├── networking/                  # Hub-and-Spoke VNet, Firewall, Bastion, NSG, UDR
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   │
│   ├── governance/                  # Management Groups, Policy Definitions, Initiative, RBAC
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   │
│   ├── monitoring/                  # Log Analytics Workspace, Defender for Cloud
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   │
│   └── identity/                    # Azure AD Groups, scoped RBAC assignments
│       ├── main.tf
│       └── variables.tf
│
├── clients/                         # Per-client, per-environment tfvars — isolated state
│   ├── client-a/
│   │   ├── prod/
│   │   │   └── terraform.tfvars    # Production config — policy enforced
│   │   └── dev/
│   │       └── terraform.tfvars    # Dev config — policy in audit mode
│   └── client-b/
│       ├── prod/
│       │   └── terraform.tfvars
│       └── dev/
│           └── terraform.tfvars
│
├── .github/
│   └── workflows/
│       └── terraform-deploy.yml    # CI: lint/plan on PR, apply on main merge
│
└── README.md
```

---

## Design Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| **IaC Tool** | Terraform ≥ 1.5 | Provider-agnostic, rich ecosystem, native test framework |
| **State Isolation** | Per-client/per-env backend key | Blast radius containment; a broken client state never affects others |
| **Multi-Subscription** | Provider aliases | Reflects real-world MSP topology; avoids cross-subscription role escalation |
| **Network Topology** | Hub-and-Spoke | CAF-aligned; centralises security inspection, reduces peering complexity |
| **Policy Delivery** | Custom Initiative | Single assignment point; easier audit, exceptions, and versioning |
| **RBAC Granularity** | MG + Subscription scope | Principle of least privilege; client team never sees other clients |
| **Naming Convention** | `msp-{client}-{env}-{type}` | Sortable, queryable, and self-documenting in Azure Portal |
| **Tag Enforcement** | Policy + locals merge | Hard deny at ARM level; no resource group escapes tagging |

---

## Prerequisites

### Tooling

| Tool | Version | Purpose |
|------|---------|---------|
| Terraform | ≥ 1.5.0 | IaC engine |
| Azure CLI | ≥ 2.55.0 | Authentication and subscription management |
| tflint | Latest | Terraform linting in CI |
| Git | ≥ 2.40 | Version control |

### Azure Requirements

1. **MSP Management Group Hierarchy** — The root MG (`mg-msp-root`) and client parent MG (`mg-msp-clients`) must exist before running this code. These are typically created once by the MSP platform team as a bootstrap step.

2. **Service Principal** — Create a dedicated SP with the following roles:
   - `Management Group Contributor` on `mg-msp-root`
   - `Owner` on Hub and Management subscriptions
   - `User Access Administrator` (required to assign RBAC roles via Terraform)

   ```bash
   az ad sp create-for-rbac \
     --name "sp-msp-terraform-platform" \
     --role "Owner" \
     --scopes "/subscriptions/<hub-sub-id>" "/subscriptions/<mgmt-sub-id>"
   ```

3. **Terraform State Storage Account** — Provision once per MSP:

   ```bash
   az group create --name rg-tfstate-msp-prod --location eastus2
   
   az storage account create \
     --name stmspterraformstate \
     --resource-group rg-tfstate-msp-prod \
     --sku Standard_GRS \
     --min-tls-version TLS1_2 \
     --allow-blob-public-access false
   
   az storage container create \
     --name tfstate \
     --account-name stmspterraformstate
   ```

4. **Azure AD Permissions** — The Service Principal must have `Directory.ReadWrite.All` or `Group.ReadWrite.All` Microsoft Graph API permissions to create Azure AD groups (required by the identity module).

---

## Onboarding a New Client

Adding a new client requires **four steps**:

### Step 1 — Allocate IP Space

Assign non-overlapping CIDRs from the MSP IP plan. Recommended allocation:

| Block | Usage |
|-------|-------|
| `10.{n}.0.0/22` | Client Hub VNet |
| `10.{n+1}.0.0/22` | Client Spoke VNet (prod) |
| `10.{n+2}.0.0/22` | Client Spoke VNet (dev) |

### Step 2 — Create Client Directory

```bash
# Replace 'client-c' and 'fabrikam' with actual values
CLIENT=client-c
mkdir -p clients/${CLIENT}/{dev,prod}
cp clients/client-a/prod/terraform.tfvars clients/${CLIENT}/prod/terraform.tfvars
cp clients/client-a/dev/terraform.tfvars  clients/${CLIENT}/dev/terraform.tfvars
```

### Step 3 — Populate tfvars

Edit `clients/${CLIENT}/prod/terraform.tfvars` with:

- New `client_subscription_id` from the subscription vending process
- Allocated CIDR blocks for `hub_vnet_config` and `spoke_vnet_config`
- Client-specific `owner_email`, `cost_center`, `client_name`, and `client_display_name`

Repeat for `dev/terraform.tfvars` using dev subscription ID and dev CIDRs.

### Step 4 — Add to CI Matrix

In `.github/workflows/terraform-deploy.yml`, add the new client to the matrix:

```yaml
matrix:
  include:
    # ... existing entries ...
    - client: client-c
      environment: dev
    - client: client-c
      environment: prod
```

Open a PR. The pipeline will run `terraform plan` automatically and post the diff as a PR comment.

---

## Deployment Steps

### Local Deployment (for development/testing)

```bash
# 1. Authenticate
az login
az account set --subscription "<management-subscription-id>"

# 2. Navigate to target client/environment
cd clients/client-a/prod

# 3. Export SP credentials
export ARM_CLIENT_ID="<sp-app-id>"
export ARM_CLIENT_SECRET="<sp-secret>"
export ARM_TENANT_ID="<tenant-id>"
export ARM_SUBSCRIPTION_ID="<management-subscription-id>"

# 4. Initialize with remote backend
terraform init \
  -backend-config="resource_group_name=rg-tfstate-msp-prod" \
  -backend-config="storage_account_name=stmspterraformstate" \
  -backend-config="container_name=tfstate" \
  -backend-config="key=client-a/prod/terraform.tfstate"

# 5. Validate
terraform validate

# 6. Plan — review output carefully
terraform plan -var-file="terraform.tfvars" -out=tfplan

# 7. Apply
terraform apply tfplan
```

### Destroying a Client Environment

```bash
# Always plan destroy first and review
terraform plan -destroy -var-file="terraform.tfvars"

# Confirm and execute
terraform destroy -var-file="terraform.tfvars"
```

> ⚠️ **Important:** The Log Analytics Workspace has `prevent_destroy = true` set. Remove this lifecycle block explicitly before running `terraform destroy` on the monitoring module in production.

---

## Module Reference

### `modules/networking`

Dual-mode module controlled by `var.mode`.

| Variable | Type | Description |
|----------|------|-------------|
| `mode` | `string` | `"hub"` or `"spoke"` |
| `address_space` | `list(string)` | VNet CIDR(s) |
| `firewall_subnet_prefix` | `string` | Hub: AzureFirewallSubnet CIDR (min /26) |
| `hub_vnet_id` | `string` | Spoke: Hub VNet ID for peering |
| `hub_firewall_private_ip` | `string` | Spoke: Firewall IP for UDR next-hop |

Key outputs: `vnet_id`, `firewall_private_ip`, `workload_subnet_id`, `data_subnet_id`

### `modules/governance`

| Variable | Type | Description |
|----------|------|-------------|
| `management_group_parent_id` | `string` | Parent MG resource ID |
| `policy_enforcement_mode` | `string` | `"Default"` (enforced) or `"DoNotEnforce"` (audit) |
| `allowed_vm_skus` | `list(string)` | Permitted VM SKUs |
| `msp_platform_team_group_id` | `string` | AAD group Object ID — Contributor on MG |

Key outputs: `management_group_id`, `policy_assignment_id`

### `modules/monitoring`

| Variable | Type | Description |
|----------|------|-------------|
| `retention_days` | `number` | Log retention (30–730) |
| `enable_defender` | `bool` | Enable Defender Standard tier |

Key outputs: `log_analytics_workspace_id`, `log_analytics_customer_id`

### `modules/identity`

| Variable | Type | Description |
|----------|------|-------------|
| `spoke_vnet_id` | `string` | Spoke VNet ID for network-scoped RBAC |
| `management_group_id` | `string` | Client MG ID for MG-scoped Reader assignment |

---

## Governance Guardrails

The MSP Baseline Policy Initiative (`[MSP] Baseline Landing Zone Guardrails`) bundles five custom policy definitions:

| Policy | Mode | Effect (prod) | Effect (dev) |
|--------|------|---------------|--------------|
| Allowed Azure Regions | `Indexed` | `Deny` | `Audit` |
| Require Mandatory Tags on RGs | `All` | `Deny` | `Audit` |
| Deny Public IP Address Creation | `Indexed` | `Deny` | `Audit` |
| Allowed VM SKUs | `Indexed` | `Deny` | `Audit` |
| Enable Defender for Cloud (DINE) | `All` | `DeployIfNotExists` | `DeployIfNotExists` |

**Exempting Hub resources from Public IP deny:**
The Hub subscription (containing Firewall and Bastion PIPs) should be added to `not_scopes` on the policy assignment. This is managed via the `not_scopes` field in `azurerm_management_group_policy_assignment.msp_baseline` in `modules/governance/main.tf`.

---

## CI/CD Pipeline

The GitHub Actions workflow (`.github/workflows/terraform-deploy.yml`) implements a safe Terraform delivery pipeline:

```
PR opened/updated
    └── lint          (terraform fmt -check, tflint)
    └── plan          (matrix: all client/env combos)
        └── Posts plan diff as PR comment

Push to main
    └── lint
    └── plan          (re-runs to produce fresh artifact)
    └── apply         (sequential, max-parallel: 1 — prevents state lock conflicts)
```

**GitHub Environments** gate production deployments. Configure required reviewers in GitHub Settings → Environments → `prod` before enabling auto-apply.

---

## Security Posture

| Control | Implementation |
|---------|---------------|
| No public IPs on workloads | Azure Policy (Deny) + NSG default-deny-internet |
| All outbound via Firewall | UDR `0.0.0.0/0 → Firewall private IP` on all spoke subnets |
| DNS via Firewall proxy | Spoke VNet DNS servers set to Firewall private IP |
| Agentless remote access | Azure Bastion Standard (tunneling, no public VM IPs) |
| Secrets in pipeline | GitHub Secrets; ARM credentials never in `.tfvars` or code |
| State encryption | Azure Storage with GRS, TLS 1.2 minimum, no public blob access |
| Least-privilege RBAC | No wildcard Owner assignments; MG-scoped Contributor for MSP team |
| Tag enforcement | Policy hard-deny on untagged resource groups |
| Threat detection | Defender for Cloud Standard on VMs, SQL, App Services, Storage |
| Audit logging | All Firewall categories + NSG flow logs to central Log Analytics |

---

## Contributing

1. Fork the repository and create a feature branch: `git checkout -b feat/your-feature`
2. Ensure `terraform fmt` passes: `terraform fmt -recursive`
3. Run `tflint --recursive` — resolve all warnings before opening a PR
4. Update `README.md` if adding new variables or modules
5. Open a PR — the pipeline will automatically post a plan diff for review

---

*Built with the Microsoft Cloud Adoption Framework Landing Zone accelerator principles. Designed for MSP scale — vend a new client in under 30 minutes.*
