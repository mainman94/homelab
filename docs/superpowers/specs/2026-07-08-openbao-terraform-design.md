# OpenBao Terraform Configuration — Design

**Date:** 2026-07-08
**Scope:** `terraform/openbao` — OpenBao server-side configuration only (Part A).
**Goal:** Stand up OpenBao (`http://192.168.0.129:30020`) as the long-term secrets
backend replacing Infisical. This spec covers server config; the in-cluster
consumer switch (Infisical secrets-operator → External Secrets Operator) is a
documented follow-up in the `multi-k8s-infra` repo (Part B), not built here.

## Background

Infisical currently plays two roles:

1. **Terraform provider** (`terraform/infisical`) — mostly demo/unused.
2. **In-cluster secrets-operator** — a single `InfisicalSecret` CR pulls ~20 keys
   from Infisical Cloud (`homelab-graz` / env `prod` / path `/`) and materializes
   Kubernetes Secrets across namespaces (cilium, portfolio*, cloudflared, argocd,
   external-dns, kargo, velero).

This design replaces the backend that role 2 reads from.

## Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Scope now | Part A only (OpenBao server config) | B is separate work in another repo |
| Cluster auth method | Kubernetes auth | No static creds; standard ESO+Vault pattern; OpenBao runs in-cluster |
| Secret values | Structure only, **no values in TF** | Never place plaintext secrets in TF state |
| State / execution | HCP Terraform, org `eggenberg-homelab`, workspace `openbao`, **Agent** execution | Homelab runner reaches NodePort + cluster API |
| Provider | `hashicorp/vault ~> 4.0` | API-compatible with OpenBao, mature. `openbao/openbao` is a drop-in fork — switch `source` later if wanted |
| Secret layout | Grouped by source under `homelab/prod/<source>` | User preference |

## Architecture

Single-workspace Terraform config, mirroring the file layout of the existing
`terraform/talos` and `terraform/infisical` configs.

### Provider & backend

- Provider `hashicorp/vault ~> 4.0`.
  - `address` from `var.vault_address` (default `http://192.168.0.129:30020`).
  - Token via **`VAULT_TOKEN`** environment variable only (HCP sensitive workspace
    var). Never a Terraform variable → never in state.
- `backend "remote"`: hostname `app.terraform.io`, org `eggenberg-homelab`,
  workspace `openbao`. Workspace execution mode set to **Agent** (homelab agent
  pool) in the HCP UI — not expressed in code.

### Resources

1. **`vault_mount.kv`** — kv-v2 secrets engine at path `homelab` (`var.kv_mount`).
2. **`vault_auth_backend.kubernetes`** — kubernetes auth method at path `kubernetes`.
3. **`vault_kubernetes_auth_backend_config.kubernetes`**
   - `kubernetes_host = "https://kubernetes.default.svc"`.
   - No `token_reviewer_jwt` / `kubernetes_ca_cert` — OpenBao runs in-cluster and
     uses its own pod ServiceAccount + mounted CA for the TokenReview API.
   - `disable_iss_validation` left at provider default (`true` for new mounts).
4. **`vault_policy.eso_reader`** — HCL policy granting `read` + `list` on:
   - `homelab/data/prod/*`
   - `homelab/metadata/prod/*`
5. **`vault_kubernetes_auth_backend_role.eso`**
   - `bound_service_account_names = [var.eso_sa_name]` (default `external-secrets`)
   - `bound_service_account_namespaces = [var.eso_namespace]` (default `external-secrets`)
   - `token_policies = [vault_policy.eso_reader.name]`
   - sensible `token_ttl` (e.g. 1h).

### Secret layout (paths created by migration, NOT by TF)

Grouped by source under the `homelab` mount, env prefix `prod`:

| Path | Keys |
|------|------|
| `homelab/prod/cloudflare` | `CLOUDFLARE_API_KEY`, `CLOUDFLARE_ACCOUNT_ID`, `CLOUDFLARE_ZONE_ID_HAUPTMANN_DEV`, `CLOUDFLARE_TUNNEL_EGGENBERG_ID`, `CLOUDFLARE_TUNNEL_EGGENBERG_SECRET`, `CLOUDFLARE_TUNNEL_EGGENBERG_CERTIFICATE` |
| `homelab/prod/github` | `ARGOCD_IMAGER_UPDATER_GIT_USERNAME`, `ARGOCD_IMAGER_UPDATER_GIT_PAT`, `GHCR_PULL_SECRET`, `GHCR_PULL_TOKEN`, `DOCKER_PULL_PAT` |
| `homelab/prod/argocd` | `ARGOCD_DEX_POCKETID_CLIENT_ID`, `ARGOCD_DEX_POCKETID_CLIENT_SECRET`, `ARGO_WORKFLOWS_SSO_CLIENT_SECRET` |
| `homelab/prod/kargo` | `KARGO_ADMIN_PASSWORD_HASH`, `KARGO_ADMIN_TOKEN_SIGNING_KEY` |
| `homelab/prod/contact` | `CONTACT_POSTGRES_PASSWORD`, `CONTACT_TELEGRAM_BOT_TOKEN`, `CONTACT_TELEGRAM_CHAT_ID`, `CONTACT_SMTP_HOST`, `CONTACT_SMTP_PORT`, `CONTACT_SMTP_USER`, `CONTACT_SMTP_PASS`, `CONTACT_SMTP_FROM`, `CONTACT_TO_EMAIL` |
| `homelab/prod/backblaze` | `BACKBLAZE_APPLICATION_KEY_ID_K8S_BACKUP`, `BACKBLAZE_APPLICATION_KEY_K8S_BACKUP` |

## File layout

```
terraform/openbao/
  backend.tf     # remote backend, workspace "openbao"
  provider.tf    # hashicorp/vault provider + required_providers
  variables.tf   # vault_address, kv_mount, eso_sa_name, eso_namespace
  main.tf        # mount, auth backend + config, policy, role
  README.md      # migration runbook + Part B note
```

## Variables

| Name | Type | Default | Purpose |
|------|------|---------|---------|
| `vault_address` | string | `http://192.168.0.129:30020` | OpenBao API address |
| `kv_mount` | string | `homelab` | kv-v2 mount path |
| `eso_sa_name` | string | `external-secrets` | Bound SA name for k8s auth role |
| `eso_namespace` | string | `external-secrets` | Bound SA namespace |

Token is **not** a variable — supplied via `VAULT_TOKEN` env in the HCP workspace.

## Migration runbook (README.md content)

One-time seeding of values (run against OpenBao with an admin token; values from
current Infisical export):

```sh
export BAO_ADDR=http://192.168.0.129:30020
export BAO_TOKEN=<admin-token>

bao kv put homelab/prod/cloudflare \
  CLOUDFLARE_API_KEY=... CLOUDFLARE_ACCOUNT_ID=... ...
bao kv put homelab/prod/github ...
bao kv put homelab/prod/argocd ...
bao kv put homelab/prod/kargo ...
bao kv put homelab/prod/contact ...
bao kv put homelab/prod/backblaze ...
```

(`bao` and `vault` CLIs are interchangeable against OpenBao.)

## Part B (follow-up, not in this repo)

In `multi-k8s-infra`: install External Secrets Operator, create a
`ClusterSecretStore` pointing at OpenBao via the `kubernetes` auth role `eso`,
and rewrite the ~20 managed secrets from the `InfisicalSecret` CR as
`ExternalSecret` resources (one `dataFrom`/`extract` per source path). Then
remove the Infisical secrets-operator Application.

## Out of scope

- Secret values in Terraform.
- OpenBao install / unseal / storage backend (assumed already running at the NodePort).
- Part B cluster manifests.
- HCP workspace/agent-pool provisioning (created in HCP UI).

## Testing / verification

- `terraform validate` + `terraform plan` clean.
- After apply: `bao secrets list` shows `homelab/`, `bao auth list` shows
  `kubernetes/`, `bao policy read eso-reader` matches, `bao read auth/kubernetes/role/eso`
  shows correct bindings.
- End-to-end auth verified during Part B (ESO login) — no consumer exists yet in A.
