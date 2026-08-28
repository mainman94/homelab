# GitHub Root Stack

This stack manages the GitHub repositories `mainman94/homelab`, `mainman94/homelab-terraform-modules`, `mainman94/multi-k8s-infra`, `mainman94/portfolio`, `mainman94/portfolio-performance`, `mainman94/pp-portfolio-classifier`, `mainman94/dev-config`, and `mainman94/docker-stack` via the shared GitHub module.

## Module versioning

This stack intentionally consumes tagged releases from `mainman94/homelab-terraform-modules` rather than `main`.

When the shared GitHub module changes, use this release flow:

1. Update the module in `../homelab-terraform-modules/modules/github`.
2. Validate it locally.
3. Commit and tag a new `github-x.y.z` release in the module repository.
4. Bump the `source` ref in `terraform/github/main.tf`.
5. Run `terraform init -upgrade` and `terraform plan` in this stack.

## Current repository mapping

Source of truth is `var.repositories` in [variables.tf](variables.tf); this table
only lists what differs per repository.

| Repository | Visibility | Ruleset | Notes |
|------------|-----------|---------|-------|
| `homelab` | public | default-branch-protection (+ linear history) | |
| `homelab-terraform-modules` | public | default-branch-protection (+ linear history) | projects + wiki on |
| `multi-k8s-infra` | public | default-branch-protection | auto-merge for Renovate, so no linear history |
| `pp-portfolio-classifier` | public | default-branch-protection | |
| `dev-config` | public | default-branch-protection | projects + wiki on |
| `docker-stack` | public | default-branch-protection | |
| `mainman94` | public | — | profile README repository |
| `portfolio` | private | — | rulesets need GitHub Pro on private repos |
| `portfolio-performance` | private | — | rulesets need GitHub Pro on private repos |
| `stoicful` | private | — | rulesets need GitHub Pro on private repos |
| `beartainer` | public | — | archived; GitHub rejects writes, values mirror the repository |

Every repository owned by `mainman94` is managed here — there is no
intentionally unmanaged one.

## Usage

1. The GitHub token is read from OpenBao (`homelab/prod/github`, key `PAT`) via
   the `vault` provider. Enable HCP workload-identity auth on the `github`
   workspace with these env vars (no static token):
   - `TFC_VAULT_PROVIDER_AUTH=true`
   - `TFC_VAULT_ADDR=https://vault.hauptmann.dev`
   - `TFC_VAULT_RUN_ROLE=tfc-github`
2. For local `terraform import`, export `VAULT_ADDR`/`VAULT_TOKEN` (a token with
   the `tfc-github-reader` policy) so the `vault` data source can read the PAT.
3. Run `terraform init` in this directory.
4. Import the existing repositories into state:

```bash
terraform import 'module.repositories["homelab"].github_repository.this' homelab
terraform import 'module.repositories["homelab"].github_branch_default.this[0]' homelab
terraform import 'module.repositories["homelab_terraform_modules"].github_repository.this' homelab-terraform-modules
terraform import 'module.repositories["homelab_terraform_modules"].github_branch_default.this[0]' homelab-terraform-modules
terraform import 'module.repositories["multi_k8s_infra"].github_repository.this' multi-k8s-infra
terraform import 'module.repositories["multi_k8s_infra"].github_branch_default.this[0]' multi-k8s-infra
terraform import 'module.repositories["portfolio"].github_repository.this' portfolio
terraform import 'module.repositories["portfolio"].github_branch_default.this[0]' portfolio
terraform import 'module.repositories["portfolio_performance"].github_repository.this' portfolio-performance
terraform import 'module.repositories["portfolio_performance"].github_branch_default.this[0]' portfolio-performance
terraform import 'module.repositories["pp_portfolio_classifier"].github_repository.this' pp-portfolio-classifier
terraform import 'module.repositories["pp_portfolio_classifier"].github_branch_default.this[0]' pp-portfolio-classifier
terraform import 'module.repositories["dev_config"].github_repository.this' dev-config
terraform import 'module.repositories["dev_config"].github_branch_default.this[0]' dev-config
terraform import 'module.repositories["docker_stack"].github_repository.this' docker-stack
terraform import 'module.repositories["docker_stack"].github_branch_default.this[0]' docker-stack
terraform import 'module.repositories["profile"].github_repository.this' mainman94
terraform import 'module.repositories["profile"].github_branch_default.this[0]' mainman94
terraform import 'module.repositories["stoicful"].github_repository.this' stoicful
terraform import 'module.repositories["stoicful"].github_branch_default.this[0]' stoicful
terraform import 'module.repositories["beartainer"].github_repository.this' beartainer
terraform import 'module.repositories["beartainer"].github_branch_default.this[0]' beartainer

# ruleset that was created in the UI as "Branch-Rule"; apply renames it
terraform import 'module.repositories["multi_k8s_infra"].github_repository_ruleset.this["default_branch"]' multi-k8s-infra:11212352
```

If you already imported these repositories under the older module names, Terraform will migrate the state automatically via `moved` blocks in this root module.

5. Run `terraform plan` and adjust any optional repository settings that should be managed explicitly.

## Security settings

`secret_scanning`, `secret_scanning_push_protection`, and
`dependabot_security_updates` default to enabled for every `public` repository
and are left untouched on private ones (secret scanning needs GitHub Advanced
Security there) and on archived ones (GitHub serves them read-only). Set any of
the flags on a repository in `var.repositories` to override.

Not managed here: `pull_request_creation_policy` (restricting who may open pull
requests). The GitHub provider has no attribute for it, so it is set through the
REST API and drifts silently if changed in the UI:

```bash
gh api -X PATCH repos/mainman94/<repo> -f pull_request_creation_policy=collaborators_only
```

Currently `collaborators_only` on `multi-k8s-infra` and `docker-stack`, `all` elsewhere.

## Configuration model

Repositories are configured through the `repositories` variable as a `map(object(...))`, keyed by stable Terraform identifiers. This keeps resource addresses stable while allowing repository settings to scale without duplicating dozens of root-module variables.

The object model also supports optional repository rulesets so branch governance can be defined alongside visibility, merge settings, and default branch management.

## Terraform Cloud note

Secrets come from OpenBao via HCP workload identity, not an Infisical variable
set. Do not attach unrelated secrets as Terraform variables to this workspace —
Terraform fails before import or plan with `Value for undeclared variable` errors.

For this stack, only the following inputs should normally exist in the workspace:

- `TFC_VAULT_PROVIDER_AUTH` / `TFC_VAULT_ADDR` / `TFC_VAULT_RUN_ROLE` env vars (Vault auth)
- optional Terraform variables such as `github_owner` or `vault_address` to override defaults
