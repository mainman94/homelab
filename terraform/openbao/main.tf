# kv-v2 secrets engine holding all homelab secrets, grouped by source under prod/.
resource "vault_mount" "kv" {
  path        = var.kv_mount
  type        = "kv"
  options     = { version = "2" }
  description = "Homelab secrets (replaces Infisical homelab-graz/prod)"
}

# Secret paths grouped by source. TF creates them empty; values are managed
# manually (`bao kv put homelab/prod/<source> KEY=...`). ignore_changes means
# TF never reverts those manual writes.
locals {
  secret_sources = ["cloudflare", "github", "argocd", "kargo", "contact", "backblaze"]
}

resource "vault_kv_secret_v2" "prod" {
  for_each  = toset(local.secret_sources)
  mount     = vault_mount.kv.path
  name      = "prod/${each.key}"
  data_json = jsonencode({})

  lifecycle {
    ignore_changes = [data_json]
  }
}

# Kubernetes auth for the External Secrets Operator. OpenBao runs on Docker
# (outside the cluster), so host/CA/reviewer-JWT are supplied explicitly.
resource "vault_auth_backend" "kubernetes" {
  type = "kubernetes"
}

resource "vault_kubernetes_auth_backend_config" "kubernetes" {
  backend                = vault_auth_backend.kubernetes.path
  kubernetes_host        = var.kubernetes_host
  kubernetes_ca_cert     = var.kubernetes_ca_cert
  token_reviewer_jwt     = var.token_reviewer_jwt
  disable_iss_validation = true
}

# Read-only policy for the ESO consumer.
resource "vault_policy" "eso_reader" {
  name = "eso-reader"

  policy = <<-EOT
    path "${var.kv_mount}/data/prod/*" {
      capabilities = ["read", "list"]
    }
    path "${var.kv_mount}/metadata/prod/*" {
      capabilities = ["read", "list"]
    }
  EOT
}

# Maps the ESO ServiceAccount to the reader policy.
resource "vault_kubernetes_auth_backend_role" "eso" {
  backend                          = vault_auth_backend.kubernetes.path
  role_name                        = "eso"
  bound_service_account_names      = [var.eso_sa_name]
  bound_service_account_namespaces = [var.eso_namespace]
  token_policies                   = [vault_policy.eso_reader.name]
  token_ttl                        = 3600
}

# Read/write policy for a human operator, scoped to prod/* only. No access to
# root, other mounts, or homelab paths outside prod/.
resource "vault_policy" "homelab_prod_writer" {
  name = "homelab-prod-writer"

  policy = <<-EOT
    path "${var.kv_mount}/data/prod/*" {
      capabilities = ["create", "update", "read", "delete"]
    }
    path "${var.kv_mount}/metadata/prod/*" {
      capabilities = ["list", "read", "delete"]
    }
    # Exact-path list so the UI can browse the tree: the prod/* glob above does
    # not cover listing the mount root or the prod/ dir itself.
    path "${var.kv_mount}/metadata" {
      capabilities = ["list"]
    }
    path "${var.kv_mount}/metadata/prod" {
      capabilities = ["list"]
    }
  EOT
}

# Userpass auth for human logins (non-root). Like the kv values above, the
# actual user + password is created manually so the password never lands in
# TF state:
#   bao write auth/userpass/users/homelab-user \
#     password=<secret> token_policies=homelab-prod-writer
resource "vault_auth_backend" "userpass" {
  type = "userpass"
}
