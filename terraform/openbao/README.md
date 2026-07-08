# OpenBao — Terraform config

Server-side configuration for OpenBao (`http://192.168.0.129:30020`), the
long-term replacement for Infisical. Manages **structure only** — no secret
values live in Terraform or its state.

Design: [`docs/superpowers/specs/2026-07-08-openbao-terraform-design.md`](../../docs/superpowers/specs/2026-07-08-openbao-terraform-design.md).

## What this manages

- kv-v2 secrets engine at mount `homelab` + 6 empty secret paths (values manual).
- Kubernetes auth method (`kubernetes/`) for External Secrets Operator. OpenBao
  runs on Docker (outside the cluster), so `kubernetes_host`, cluster CA, and a
  reviewer JWT are supplied as workspace vars.
- Policy `eso-reader`: `read`/`list` on `homelab/{data,metadata}/prod/*`.
- Role `eso`: binds SA `external-secrets` (ns `external-secrets`) → `eso-reader`.

## Runs

HCP Terraform, org `eggenberg-homelab`, workspace `openbao`, **Agent** execution
(homelab agent pool — reaches the NodePort). Workspace vars:

| Var | Kind | Value |
|-----|------|-------|
| `VAULT_TOKEN` | env, sensitive | OpenBao admin token |
| `kubernetes_ca_cert` | terraform, sensitive | cluster CA PEM |
| `token_reviewer_jwt` | terraform, sensitive | reviewer SA JWT (below) |

## Bootstrap the reviewer ServiceAccount (one-time, run against the cluster)

OpenBao validates cluster JWTs via the TokenReview API using this reviewer SA
(non-expiring token):

```sh
kubectl apply -f - <<'EOF'
apiVersion: v1
kind: ServiceAccount
metadata: { name: openbao-reviewer, namespace: kube-system }
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata: { name: openbao-reviewer }
roleRef: { apiGroup: rbac.authorization.k8s.io, kind: ClusterRole, name: system:auth-delegator }
subjects: [{ kind: ServiceAccount, name: openbao-reviewer, namespace: kube-system }]
---
apiVersion: v1
kind: Secret
metadata:
  name: openbao-reviewer-token
  namespace: kube-system
  annotations: { kubernetes.io/service-account.name: openbao-reviewer }
type: kubernetes.io/service-account-token
EOF

# token_reviewer_jwt:
kubectl get secret openbao-reviewer-token -n kube-system -o jsonpath='{.data.token}' | base64 -d
# kubernetes_ca_cert:
kubectl config view --raw --minify -o jsonpath='{.clusters[0].cluster.certificate-authority-data}' | base64 -d
```

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

## Cluster side — follow-up (`multi-k8s-infra`)

Not built here. Install External Secrets Operator (SA `external-secrets`, ns
`external-secrets`), add a `ClusterSecretStore` using OpenBao auth role `eso`,
rewrite the ~20 secrets from the `InfisicalSecret` CR as `ExternalSecret`s (one
`extract` per source path), then remove the Infisical secrets-operator
Application.
