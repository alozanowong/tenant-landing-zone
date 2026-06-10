# Security Policy

## Supported Versions

This repository is a reference blueprint, not a versioned product. The `main`
branch always reflects the current recommended configuration. Older commits are
not actively maintained.

## Reporting a Vulnerability

**Please do not open a public GitHub Issue for security vulnerabilities.**

If you discover a security issue in this repository — including but not limited
to exposed credentials, insecure default configurations, policy bypasses, or
privilege escalation paths in the Terraform code — please report it privately:

**Contact:** Open a [GitHub Security Advisory](../../security/advisories/new)
on this repository (Settings → Security → Advisories → New draft advisory).

Alternatively, you may reach out directly via the contact information on my
[GitHub profile](https://github.com/your-github-username).

## What to Include

To help triage the report quickly, please include:

- A description of the vulnerability and its potential impact
- The affected file(s) and line numbers
- Steps to reproduce or a proof-of-concept (where applicable)
- Any suggested remediation

## Response Commitment

I will acknowledge receipt within **72 hours** and aim to publish a fix or
mitigation guidance within **14 days** for confirmed vulnerabilities.

## Scope

This policy covers security issues within this repository's Terraform code,
module logic, CI/CD pipeline configuration, and documentation.

It does **not** cover:
- Your own Azure environment or deployed infrastructure
- Third-party providers (AzureRM, AzureAD) — report those upstream to HashiCorp
- Microsoft Azure platform vulnerabilities — report those to [MSRC](https://msrc.microsoft.com)

## Credential Leak Protocol

If you find what appears to be a real credential, subscription ID, or secret
accidentally committed to this repository, please report it immediately via the
advisory process above. Do not attempt to use or validate the credential.

---

Thank you for helping keep this project and its users secure.
