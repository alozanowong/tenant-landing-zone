# Changelog

All notable changes to this project will be documented here.

Format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).
This project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [1.0.0] — 2026-06-10

### Added

- **Hub-and-Spoke networking module** — dual-mode (`hub`/`spoke`) supporting Azure Firewall Standard (zone-redundant), Azure Bastion Standard with tunneling, User-Defined Routes forcing all spoke egress through Firewall, and bidirectional VNet peering
- **Governance module** — client Management Group hierarchy, five custom Azure Policy definitions (allowed regions, mandatory tags, deny public IPs, allowed VM SKUs, enable Defender for Cloud DINE), bundled into a single Policy Initiative with per-environment enforcement mode switching
- **Monitoring module** — central Log Analytics Workspace with configurable retention, Microsoft Defender for Cloud Standard tier across VMs, SQL, App Services, and Storage
- **Identity module** — Azure AD group provisioning and scoped RBAC assignments (Contributor for MSP platform team, Security Reader for MSP security team, Reader for client admins)
- **Multi-tenant client directory** — `clients/{client}/{env}/terraform.tfvars` pattern with isolated remote state keys per client/environment
- **GitHub Actions CI/CD pipeline** — matrix plan on PR with automatic PR comment, sequential apply on merge to `main`, tflint + fmt lint gate
- **Root variable validation** — GUID regex on all subscription/tenant IDs, CIDR validation on all network blocks, enum constraints on environment and enforcement mode
- **CAF-aligned naming convention** — `msp-{client}-{env}-{resource_type}` enforced via `locals.tf`
- **Mandatory tag baseline** — tag merge pattern with hard policy deny on untagged resource groups
- `.gitignore` blocking state files, plan artifacts, credentials, and auto-loaded tfvars
- `SECURITY.md` with responsible disclosure process
- `LICENSE` — MIT

[1.0.0]: https://github.com/your-github-username/msp-azure-landing-zone/releases/tag/v1.0.0
