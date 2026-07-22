# GitHub Actions workload-identity auth. Lets repo workflows read scoped secrets
# from OpenBao with a short-lived per-run OIDC token instead of a static
# VAULT_TOKEN or duplicated GitHub repo secrets. Same pattern as tfc-vault-auth.tf.
#
# Workflow side (hashicorp/vault-action), needs `permissions: id-token: write`:
#   - uses: hashicorp/vault-action@v3
#     with:
#       url: https://vault.hauptmann.dev
#       method: jwt
#       path: github-actions
#       role: gha-portfolio
#       secrets: homelab/data/prod/zot ADMIN_PASSWORD | REGISTRY_PASSWORD
# GitHub mints the OIDC token; its default audience is the repo owner URL
# (https://github.com/<owner>), which is what bound_audiences pins below.

resource "vault_jwt_auth_backend" "github_actions" {
  path               = "github-actions"
  type               = "jwt"
  description        = "GitHub Actions workload identity (OIDC) for repo workflows"
  oidc_discovery_url = "https://token.actions.githubusercontent.com"
  bound_issuer       = "https://token.actions.githubusercontent.com"
}

locals {
  # role key -> { repository = "owner/repo", ref, KV sources it may read }
  github_repo_roles = {
    "portfolio" = {
      repository = "mainman94/portfolio"
      ref        = "refs/heads/main"
      sources    = ["zot"]
    }
  }
}

# Read-only policy per role, scoped to that role's KV paths.
resource "vault_policy" "gha_reader" {
  for_each = local.github_repo_roles
  name     = "gha-${each.key}-reader"

  policy = join("\n", [
    for source in each.value.sources : <<-EOT
      path "${var.kv_mount}/data/prod/${source}" {
        capabilities = ["read"]
      }
    EOT
  ])
}

# JWT role bound to the repo + branch claims -> scoped policy.
resource "vault_jwt_auth_backend_role" "github_actions" {
  for_each  = local.github_repo_roles
  backend   = vault_jwt_auth_backend.github_actions.path
  role_name = "gha-${each.key}"
  role_type = "jwt"

  user_claim        = "repository"
  bound_audiences   = [var.github_actions_vault_audience]
  bound_claims_type = "string"
  bound_claims = {
    repository = each.value.repository
    ref        = each.value.ref
  }

  token_policies = [vault_policy.gha_reader[each.key].name]
  token_ttl      = 900
  token_max_ttl  = 1800
}
