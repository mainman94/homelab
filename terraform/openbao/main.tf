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
