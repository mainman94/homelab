# GitHub Root Stack

This stack manages the GitHub repositories `mainman94/homelab`, `mainman94/homelab-terraform-modules`, and `mainman94/multi-k8s-infra` via the shared GitHub module.

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
- Repository: `homelab-terraform-modules`
- Visibility: `public`
- Issues: enabled
- Projects: enabled
- Wiki: enabled
- Homepage: unset
- Description: unset
- Default branch: `main`
- Repository: `multi-k8s-infra`
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
```

If you already imported these repositories under the older module names, Terraform will migrate the state automatically via `moved` blocks in this root module.

## Configuration model

Repositories are configured through the `repositories` variable as a `map(object(...))`, keyed by stable Terraform identifiers. This keeps resource addresses stable while allowing repository settings to scale without duplicating dozens of root-module variables.

5. Run `terraform plan` and adjust any optional repository settings that should be managed explicitly.

## Terraform Cloud note

If this workspace receives a shared Infisical-synced variable set, make sure repository-unrelated secrets are not attached as Terraform variables to the `github` workspace. Otherwise Terraform fails before import or plan with `Value for undeclared variable` errors.

For this stack, only the following inputs should normally exist in the workspace:

- `GITHUB_TOKEN` as an environment variable
- optional Terraform variables such as `github_owner` when you want to override defaults
