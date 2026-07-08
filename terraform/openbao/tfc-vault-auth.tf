# HCP Terraform (Terraform Cloud) workload-identity auth. Lets the other TF
# stacks authenticate to OpenBao with a short-lived, per-run OIDC token instead
# of a static VAULT_TOKEN — this replaces the old Infisical -> TFC variable-set
# sync. Each workspace gets a JWT role scoped read-only to its own KV path.
#
# HCP side (set per consumer workspace, NOT in code — HCP UI env vars):
#   TFC_VAULT_PROVIDER_AUTH = true
#   TFC_VAULT_ADDR          = https://vault.hauptmann.dev
#   TFC_VAULT_RUN_ROLE      = tfc-<workspace>        (e.g. tfc-github)
# HCP exchanges the run's workload-identity token for a Vault token and injects
# VAULT_TOKEN into the run; the stack's vault provider + data sources use it
# transparently. Default token audience is "vault.workload.identity".

resource "vault_jwt_auth_backend" "tfc" {
  path               = "tfc"
  type               = "jwt"
  description        = "HCP Terraform workload identity (OIDC) for consumer stacks"
  oidc_discovery_url = "https://app.terraform.io"
  bound_issuer       = "https://app.terraform.io"
}

locals {
  # TFC workspace name -> KV source path (prod/<source>) it may read.
  tfc_workspace_sources = {
    "github"     = "github"
    "cloudflare" = "cloudflare"
    "backblaze"  = "backblaze"
  }
}

# Read-only policy per workspace, scoped to that workspace's single KV path.
resource "vault_policy" "tfc_reader" {
  for_each = local.tfc_workspace_sources
  name     = "tfc-${each.key}-reader"

  policy = <<-EOT
    path "${var.kv_mount}/data/prod/${each.value}" {
      capabilities = ["read"]
    }
  EOT
}

# JWT role bound to the specific HCP org + workspace claims -> scoped policy.
resource "vault_jwt_auth_backend_role" "tfc" {
  for_each  = local.tfc_workspace_sources
  backend   = vault_jwt_auth_backend.tfc.path
  role_name = "tfc-${each.key}"
  role_type = "jwt"

  user_claim        = "terraform_full_workspace"
  bound_audiences   = [var.tfc_vault_audience]
  bound_claims_type = "string"
  bound_claims = {
    terraform_organization_name = var.tfc_organization
    terraform_workspace_name    = each.key
  }

  token_policies = [vault_policy.tfc_reader[each.key].name]
  token_ttl      = 900
  token_max_ttl  = 1800
}
