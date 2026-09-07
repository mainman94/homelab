# Terraform Cloud (TFE) — Workspaces as Code

Manages HCP Terraform / Terraform Cloud workspaces, execution settings, agent pools, and workload-identity environment variables for the `eggenberg-homelab` organization using the `hashicorp/tfe` provider.

## Managed Workspaces

| Workspace | Working Directory | Execution Mode | Vault Auth Role |
|---|---|---|---|
| `cloudflare` | `terraform/cloudflare` | Agent (`homelab-eggenberg`) | `tfc-cloudflare` |
| `github` | `terraform/github` | Agent (`homelab-eggenberg`) | `tfc-github` |
| `backblaze` | `terraform/infrastructure` | Agent (`homelab-eggenberg`) | `tfc-backblaze` |
| `openbao` | `terraform/openbao` | Agent (`homelab-eggenberg`) | — |
| `pocket-id` | `terraform/pocket-id` | Agent (`homelab-eggenberg`) | `tfc-pocket-id` |
| `eggenberg-talos-cluster` | `terraform/talos` | Local / Workstation | — |
| `tfe` | `terraform/tfe` | Remote | — |

## Workload Identity Environment Variables

For consumer workspaces (`cloudflare`, `github`, `backblaze`, `pocket-id`), this stack manages the OpenBao OIDC authentication variables:
- `TFC_VAULT_PROVIDER_AUTH = "true"`
- `TFC_VAULT_ADDR          = var.vault_address` (`http://192.168.0.129:30020`)
- `TFC_VAULT_AUTH_PATH     = "tfc"`
- `TFC_VAULT_RUN_ROLE      = "tfc-<workspace>"`

## Authentication & Initial Apply

To run or apply this stack locally:
1. Export a Terraform Cloud User or Team token:
   ```bash
   export TFE_TOKEN="<your-tfc-token>"
   ```
2. Initialize and plan:
   ```bash
   terraform -chdir=terraform/tfe init
   terraform -chdir=terraform/tfe plan
   ```
3. Existing workspaces are imported declaratively via `imports.tf` (Terraform 1.5+).
