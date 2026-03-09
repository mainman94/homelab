# GitHub Root Stack

This stack manages the GitHub repositories `mainman94/homelab`, `mainman94/homelab-terraform-modules`, `mainman94/multi-k8s-infra`, `mainman94/portfolio`, `mainman94/portfolio-performance`, and `mainman94/dev-config` via the shared GitHub module.

## Module versioning

This stack intentionally consumes tagged releases from `mainman94/homelab-terraform-modules` rather than `main`.

When the shared GitHub module changes, use this release flow:

1. Update the module in `../homelab-terraform-modules/modules/github`.
2. Validate it locally.
3. Commit and tag a new `github-x.y.z` release in the module repository.
4. Bump the `source` ref in `terraform/github/main.tf`.
5. Run `terraform init -upgrade` and `terraform plan` in this stack.

## Current repository mapping

- Owner: `mainman94`
- Repository: `homelab`
- Visibility: `public`
- Issues: enabled
- Projects: disabled
- Wiki: disabled
- Homepage: unset
- Description: unset
- Default branch: `main`
- Rulesets: `default-branch-protection`
- Repository: `homelab-terraform-modules`
- Visibility: `public`
- Issues: enabled
- Projects: enabled
- Wiki: enabled
- Homepage: unset
- Description: unset
- Default branch: `main`
- Rulesets: `default-branch-protection`
- Repository: `multi-k8s-infra`
- Visibility: `public`
- Issues: enabled
- Projects: enabled
- Wiki: enabled
- Homepage: unset
- Description: unset
- Default branch: `main`
- Repository: `portfolio`
- Visibility: `private`
- Issues: enabled
- Projects: enabled
- Wiki: disabled
- Homepage: unset
- Description: `Personal Portfolio Page`
- Default branch: `main`
- Repository: `portfolio-performance`
- Visibility: `private`
- Issues: enabled
- Projects: enabled
- Wiki: disabled
- Homepage: unset
- Description: `Private portfolio performance files`
- Default branch: `main`
- Repository: `dev-config`
- Visibility: `public`
- Issues: enabled
- Projects: enabled
- Wiki: enabled
- Homepage: unset
- Description: unset
- Default branch: `main`

## Usage

1. In Terraform Cloud, set `GITHUB_TOKEN` as an environment variable for the `github` workspace.
2. For local `terraform import`, make sure the same token is also present in your local shell as `GITHUB_TOKEN`.
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
terraform import 'module.repositories["dev_config"].github_repository.this' dev-config
terraform import 'module.repositories["dev_config"].github_branch_default.this[0]' dev-config
```

If you already imported these repositories under the older module names, Terraform will migrate the state automatically via `moved` blocks in this root module.

## Configuration model

Repositories are configured through the `repositories` variable as a `map(object(...))`, keyed by stable Terraform identifiers. This keeps resource addresses stable while allowing repository settings to scale without duplicating dozens of root-module variables.

The object model also supports optional repository rulesets so branch governance can be defined alongside visibility, merge settings, and default branch management.

5. Run `terraform plan` and adjust any optional repository settings that should be managed explicitly.

## Terraform Cloud note

If this workspace receives a shared Infisical-synced variable set, make sure repository-unrelated secrets are not attached as Terraform variables to the `github` workspace. Otherwise Terraform fails before import or plan with `Value for undeclared variable` errors.

For this stack, only the following inputs should normally exist in the workspace:

- `GH_TOKEN` as an environment variable
- optional Terraform variables such as `github_owner` when you want to override defaults
