# OpenBao — Terraform config

Server-side configuration for OpenBao (`http://192.168.0.129:30020`), the
long-term replacement for Infisical. Manages **structure only** — no secret
values live in Terraform or its state.

Design: [`docs/superpowers/specs/2026-07-08-openbao-terraform-design.md`](../../docs/superpowers/specs/2026-07-08-openbao-terraform-design.md).

## What this manages

- kv-v2 secrets engine at mount `homelab`.

Auth method / policies / roles for the cluster consumer are **not** managed here
yet — deferred with the ESO consumer switch (Part B).

## Runs

HCP Terraform, org `eggenberg-homelab`, workspace `openbao`, **Agent** execution
(homelab agent pool — reaches the NodePort). Set workspace sensitive env var
`VAULT_TOKEN` to an OpenBao admin token.

## Secret migration (one-time, manual — values never go through Terraform)

Seed the values from the current Infisical export. `bao` and `vault` CLIs are
interchangeable against OpenBao.

```sh
export BAO_ADDR=http://192.168.0.129:30020
export BAO_TOKEN=<admin-token>

bao kv put homelab/prod/cloudflare \
  CLOUDFLARE_API_KEY=... \
  CLOUDFLARE_ACCOUNT_ID=... \
  CLOUDFLARE_ZONE_ID_HAUPTMANN_DEV=... \
  CLOUDFLARE_TUNNEL_EGGENBERG_ID=... \
  CLOUDFLARE_TUNNEL_EGGENBERG_SECRET=... \
  CLOUDFLARE_TUNNEL_EGGENBERG_CERTIFICATE=...

bao kv put homelab/prod/github \
  ARGOCD_IMAGER_UPDATER_GIT_USERNAME=... \
  ARGOCD_IMAGER_UPDATER_GIT_PAT=... \
  GHCR_PULL_SECRET=... \
  GHCR_PULL_TOKEN=... \
  DOCKER_PULL_PAT=...

bao kv put homelab/prod/argocd \
  ARGOCD_DEX_POCKETID_CLIENT_ID=... \
  ARGOCD_DEX_POCKETID_CLIENT_SECRET=... \
  ARGO_WORKFLOWS_SSO_CLIENT_SECRET=...

bao kv put homelab/prod/kargo \
  KARGO_ADMIN_PASSWORD_HASH=... \
  KARGO_ADMIN_TOKEN_SIGNING_KEY=...

bao kv put homelab/prod/contact \
  CONTACT_POSTGRES_PASSWORD=... \
  CONTACT_TELEGRAM_BOT_TOKEN=... \
  CONTACT_TELEGRAM_CHAT_ID=... \
  CONTACT_SMTP_HOST=... \
  CONTACT_SMTP_PORT=... \
  CONTACT_SMTP_USER=... \
  CONTACT_SMTP_PASS=... \
  CONTACT_SMTP_FROM=... \
  CONTACT_TO_EMAIL=...

bao kv put homelab/prod/backblaze \
  BACKBLAZE_APPLICATION_KEY_ID_K8S_BACKUP=... \
  BACKBLAZE_APPLICATION_KEY_K8S_BACKUP=...
```

## Verify after apply

```sh
bao secrets list                        # homelab/ present
bao auth list                           # kubernetes/ present
bao policy read eso-reader
bao read auth/kubernetes/role/eso       # bound SA + policies correct
```

## Part B — follow-up (deferred)

Not built here. Adds:

- **OpenBao side (this repo):** kubernetes auth method + config
  (`kubernetes_host`, cluster CA, reviewer JWT — OpenBao runs on Docker, outside
  the cluster), a read-only policy, and a role binding the ESO ServiceAccount.
- **Cluster side (`multi-k8s-infra`):** install External Secrets Operator, add a
  `ClusterSecretStore` using that auth role, rewrite the ~20 secrets from the
  `InfisicalSecret` CR as `ExternalSecret`s (one `extract` per source path), then
  remove the Infisical secrets-operator Application.
