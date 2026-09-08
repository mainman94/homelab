# HomeLab MK2

Infrastructure as Code for the homelab control plane, repository governance, and supporting cloud services.

## Overview

This repository contains Terraform stacks for:

- Cloudflare DNS, mail routing, and tunnel-backed records
- GitHub repository governance and metadata management
- OpenBao (Vault) secret backend structure, auth, and policies
- Shared infrastructure services such as Backblaze-managed storage wiring
- OCI free-tier Kubernetes infrastructure
- Talos bare-metal cluster bootstrapping

## Repository structure

```text
.
├── .github/workflows/          # CI: hooks, per-stack validate, tftest, trivy
├── .pre-commit-config.yaml     # Commit-time checks (see AGENTS.md)
├── .terraformignore            # Files excluded from Terraform Cloud uploads
├── .tflint.hcl                 # tflint ruleset
├── .trivyignore                # Accepted trivy findings, each with a reason
├── mise.toml                   # The toolchain — terraform, tflint, python, …
├── renovate.json               # Dependency update policy
├── ansible/                    # Router playbook (Cloudflare inbound allowlist)
└── terraform/
    ├── cloudflare/             # Cloudflare DNS, mail, and tunnel configuration
    ├── github/                 # GitHub repositories and branch governance
    ├── openbao/                # OpenBao (Vault) mounts, auth, and policies
    ├── infrastructure/         # Shared infrastructure integrations
    ├── oci-free-cloud-k8s/     # OCI network and Kubernetes resources
    └── talos/                  # Bare-metal Talos cluster bootstrapping
```

Shared Terraform modules live in the sibling repository `../homelab-terraform-modules`.

## Prerequisites

- **Terraform, not OpenTofu.** Four stacks (`cloudflare`, `github`,
  `infrastructure`, `pocket-id`) read credentials through an `ephemeral` block,
  a Terraform >= 1.10 feature OpenTofu does not implement — `tofu validate`
  fails on those four.
- `mise install` (or `make tools`) installs the pinned toolchain from
  `mise.toml`: terraform, tflint, python, pre-commit, actionlint, shellcheck
  and trivy. CI installs from the same file, so a local run and a CI run agree.
  `.devcontainer/` does this for you and adds ansible.
- Access to the relevant Cloudflare, GitHub, OpenBao, Backblaze, and OCI accounts
- Terraform Cloud workspace access for remote runs
- Required secrets exposed either through Terraform Cloud variables or local environment variables for import workflows

## Working with stacks

Each stack under `terraform/` is a separate root module. A typical workflow is:

1. Change into the desired stack, for example `terraform/github`.
2. Run `terraform init` or `terraform init -upgrade` after source or provider changes.
3. Review with `terraform plan`.
4. Apply with `terraform apply` once the plan is correct.

Before opening a pull request, `make check` runs everything CI does that needs
no credentials: the pre-commit hooks, `terraform validate` for every stack, and
the `terraform test` suites. `make help` lists the rest. AGENTS.md explains what
those checks do and — more usefully — what they cannot see.

Shared modules are pinned by tag (`?ref=github-0.1.9`). Those tags are cut by
the release workflow in `homelab-terraform-modules` when a module's `VERSION`
changes; bumping a pin here is how a module change reaches these stacks.

## GitHub governance stack

`terraform/github` manages repository settings through a `map(object)` model so new repositories can be added without duplicating root-module variables.

The stack currently manages eleven repositories:

- `mainman94/beartainer`
- `mainman94/dev-config`
- `mainman94/docker-stack`
- `mainman94/docker-strapi`
- `mainman94/homelab`
- `mainman94/homelab-terraform-modules`
- `mainman94/mainman94`
- `mainman94/multi-k8s-infra`
- `mainman94/portfolio`
- `mainman94/portfolio-performance`
- `mainman94/pp-portfolio-classifier`

It also manages repository rulesets. The `default-branch-protection` ruleset
prevents force pushes and branch deletion and requires a pull request on the
default branch.

Five repositories additionally require status checks to pass before a pull
request can merge — `homelab`, `homelab-terraform-modules`, `multi-k8s-infra`,
`docker-stack` and `docker-strapi`. Two details about that block are easy to get
wrong:

- A `context` must match the **job name** GitHub reports, not the workflow name
  and not the job id. For a matrix job that is the expanded form, such as
  `validate (cloudflare)`.
- `integration_id = 15368` scopes the check to the GitHub Actions app, so an
  unrelated app cannot satisfy a required context.

A required context that never reports leaves every pull request permanently
`blocked`, so **never require a check from a path-filtered workflow** — on a pull
request that does not touch those paths the job simply never runs.

## Talos bare-metal stack

`terraform/talos` manages the bootstrapping of a Talos Linux cluster on bare metal. It uses a Terraform-first workflow to:

- Generate machine configurations based on schematics and patches.
- Manage cluster secrets and bootstrap the first control-plane node.
- Scale the control plane to a 3-node HA setup.
- Integrate with Longhorn for distributed storage.

Detailed instructions can be found in `terraform/talos/README.md`.

## Module release flow

The stacks pin tagged module releases from `mainman94/homelab-terraform-modules`
(`?ref=github-0.1.9`), never a branch.

When a shared module changes:

1. Update the module in `../homelab-terraform-modules/modules/<name>`.
2. Bump that module's `VERSION` file in the same pull request — CI fails the
   `version bump` job otherwise.
3. Merge. The release workflow there tags `<name>-x.y.z` and publishes a GitHub
   release; nothing is tagged by hand.
4. Update the module `ref` here.
5. Run `terraform init -upgrade` and `terraform plan` in the affected stack.

## CI and security

- **`ci.yml`** — `pre-commit` on every file, then a `validate` matrix
  (`terraform init -backend=false`, `validate`, `fmt -check`, `tflint`) over all
  eight stacks, then `tftest (talos)`.
- **`trivy.yml`** — config scanning, uploaded to GitHub code scanning.
  Accepted findings live in `.trivyignore`, each with a written reason; there is
  no `.tfsec.yml` (trivy replaced tfsec).
- **Renovate** keeps providers, modules and actions current. Actions are pinned
  to commit SHAs and updated by digest.
- Every workflow is linted by `actionlint` and audited by `zizmor` through
  pre-commit, so a workflow change is checked before it ever runs.

## Terraform Cloud uploads

`.terraformignore` keeps Terraform Cloud uploads smaller by excluding editor, VCS, and local Terraform working-directory artifacts that are not required for remote runs.

## Notes

- Sensitive values should be supplied via Terraform Cloud variables or secure local environment variables
- Existing imported GitHub resources are tracked through Terraform state and refactored addresses use `moved` blocks where needed
