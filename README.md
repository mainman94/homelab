# HomeLab MK2

Infrastructure as Code for the homelab control plane, repository governance, and supporting cloud services.

## Overview

This repository contains Terraform stacks for:

- Cloudflare DNS, mail routing, and tunnel-backed records
- GitHub repository governance and metadata management
- Infisical project and secret automation
- Shared infrastructure services such as Backblaze-managed storage wiring
- OCI free-tier Kubernetes infrastructure

## Repository structure

```text
.
├── .github/workflows/          # CI workflows
├── .terraformignore            # Files excluded from Terraform Cloud uploads
├── .tfsec.yml                  # Central tfsec policy configuration
├── renovate.json               # Dependency update policy
└── terraform/
    ├── cloudflare/             # Cloudflare DNS, mail, and tunnel configuration
    ├── github/                 # GitHub repositories and branch governance
    ├── infisical/              # Infisical projects, environments, and secrets
    ├── infrastructure/         # Shared infrastructure integrations
    └── oci-free-cloud-k8s/     # OCI network and Kubernetes resources
```

Shared Terraform modules live in the sibling repository `../homelab-terraform-modules`.

## Prerequisites

- Terraform or OpenTofu
- Access to the relevant Cloudflare, GitHub, Infisical, Backblaze, and OCI accounts
- Terraform Cloud workspace access for remote runs
- Required secrets exposed either through Terraform Cloud variables or local environment variables for import workflows

## Working with stacks

Each stack under `terraform/` is a separate root module. A typical workflow is:

1. Change into the desired stack, for example `terraform/github`.
2. Run `terraform init` or `terraform init -upgrade` after source or provider changes.
3. Review with `terraform plan`.
4. Apply with `terraform apply` once the plan is correct.

## GitHub governance stack

`terraform/github` manages repository settings through a `map(object)` model so new repositories can be added without duplicating root-module variables.

The stack currently manages:

- `mainman94/homelab`
- `mainman94/homelab-terraform-modules`
- `mainman94/multi-k8s-infra`
- `mainman94/portfolio`
- `mainman94/portfolio-performance`
- `mainman94/dev-config`

It also supports repository rulesets. The current defaults enable a `default-branch-protection` ruleset for selected repositories to prevent force pushes and branch deletion and to require pull requests on the default branch.

## Module release flow

The GitHub root stack intentionally pins tagged module releases from `mainman94/homelab-terraform-modules`.

When the shared GitHub module changes:

1. Update `../homelab-terraform-modules/modules/github`.
2. Validate the module locally.
3. Commit and tag a new `github-x.y.z` release in the module repository.
4. Update the module `ref` in `terraform/github/main.tf`.
5. Run `terraform init -upgrade` and `terraform plan` in `terraform/github`.

## CI and security

This repository currently includes:

- `tfsec` scanning uploaded to GitHub code scanning
- central tfsec exclusions in `.tfsec.yml`
- Renovate for dependency and action updates

## Terraform Cloud uploads

`.terraformignore` keeps Terraform Cloud uploads smaller by excluding editor, VCS, and local Terraform working-directory artifacts that are not required for remote runs.

## Notes

- Sensitive values should be supplied via Terraform Cloud variables or secure local environment variables
- Existing imported GitHub resources are tracked through Terraform state and refactored addresses use `moved` blocks where needed
