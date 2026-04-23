# OpenBao Baseline (Namespaces + Auth)

Dieses Terraform-Setup erstellt pro Domain einen OpenBao Namespace mit `kv-v2` Mount und richtet Auth-Bausteine ein:

- Kubernetes Auth + Rollen pro `domain + k8s namespace + serviceaccount` (für Vault Secrets Operator)
- GitHub OIDC JWT Auth + Rollen pro Domain/Repository
- Least-Privilege Pfade pro Domain (`domain_kv_access`)
- kurze, konfigurierbare Token-TTLs für K8s/GitHub Rollen

Secret-Werte werden **nicht** durch Terraform gesetzt.

## 1) Beispiel-Konfiguration

Nutze [terraform.tfvars.example](/Users/philipp/work/homelab/terraform/openbao/terraform.tfvars.example) als Vorlage.

Wichtig:

- `secret_domains` definiert deine Namespaces (z. B. `github`, `smtp`, `dockerhub`)
- `k8s_access_by_domain` steuert, welche `namespace/serviceaccount`-Kombination pro Domain lesen darf
- `domain_kv_access` begrenzt Lesepfade je Domain getrennt für K8s und GitHub
- `github_access_by_domain` steuert OIDC-Claims pro Repo (optional mit `ref` und `environment`)
- `k8s_host`, `k8s_ca_cert`, optional `k8s_token_reviewer_jwt` für Kubernetes Auth

Standard-Härtung in diesem Setup:

- `k8s_disable_iss_validation = false`
- K8s Token TTL: `3600` (max `14400`)
- GitHub Token TTL: `900` (max `3600`, `10` uses)
- `prevent_destroy` für Namespaces, KV-Mounts und Auth-Mounts

## 2) Secrets manuell setzen (nicht via Terraform)

Beispiel:

```bash
vault kv put -namespace=github kv/runtime/app token="..."
vault kv put -namespace=github kv/ci/actions token="..."
vault kv put -namespace=smtp kv/runtime/relay username="..." password="..."
vault kv put -namespace=dockerhub kv/ci/push username="..." token="..."
```

## 3) Kubernetes Nutzung (Vault Secrets Operator)

Nutze pro Domain die jeweilige OpenBao Role:

`k8s-<domain>-<k8s-namespace>-<serviceaccount>-read`

Beispiel mit VSO (`secrets.hashicorp.com/v1beta1`):

```yaml
apiVersion: secrets.hashicorp.com/v1beta1
kind: VaultConnection
metadata:
  name: openbao
  namespace: ci
spec:
  address: https://openbao.example.com:8200
---
apiVersion: secrets.hashicorp.com/v1beta1
kind: VaultAuth
metadata:
  name: openbao-github-ci
  namespace: ci
spec:
  vaultConnectionRef: openbao
  namespace: github
  method: kubernetes
  mount: kubernetes
  kubernetes:
    role: k8s-github-ci-vault-secrets-operator-read
    serviceAccount: vault-secrets-operator
---
apiVersion: secrets.hashicorp.com/v1beta1
kind: VaultStaticSecret
metadata:
  name: github-actions-token
  namespace: ci
spec:
  vaultAuthRef: openbao-github-ci
  namespace: github
  mount: kv
  type: kv-v2
  path: runtime/app
  destination:
    name: github-actions-token
    create: true
```

## 4) GitHub Actions Nutzung (OIDC)

Workflow benötigt:

- `permissions: id-token: write`
- Vault Login via JWT-Rolle aus Terraform Output `github_roles`
- Claim-Bindings aus Terraform, z. B. `repository=my-org/repo-a` und `ref=refs/heads/main`
- Output-Key-Format für `github_roles`: `domain:org/repo:ref:environment` (`*` wenn nicht gesetzt)

Beispiel:

```yaml
permissions:
  id-token: write
  contents: read

steps:
  - name: Vault login (OIDC)
    run: |
      JWT="$(curl -sLS \
        -H "Authorization: bearer $ACTIONS_ID_TOKEN_REQUEST_TOKEN" \
        "${ACTIONS_ID_TOKEN_REQUEST_URL}&audience=vault" | jq -r .value)"

      vault write -field=token \
        -namespace=github \
        auth/github/login \
        role="REPLACE_WITH_TERRAFORM_OUTPUT_GITHUB_ROLE" \
        jwt="$JWT"
```

## 5) Betriebs-Hinweise

- Für Terraform ein dediziertes, eingeschränktes Admin-Token nutzen (kein Root-Token).
- `k8s_token_reviewer_jwt` liegt als sensitive Wert im Terraform State; State-Zugriff streng halten.
