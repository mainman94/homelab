# Cloudflare Access apps — gate sensitive self-hosted UIs behind identity,
# on top of whatever auth the app itself has. Login defaults to Cloudflare's
# built-in one-time-PIN email verification (no external IdP required).

resource "cloudflare_zero_trust_access_identity_provider" "pocket_id" {
  account_id = var.cloudflare_account_id
  name       = "Pocket ID"
  type       = "oidc"

  config = {
    client_id     = data.vault_kv_secret_v2.pocket_id_access.data["CLIENT_ID"]
    client_secret = data.vault_kv_secret_v2.pocket_id_access.data["CLIENT_SECRET"]
    auth_url      = "https://id.hauptmann.dev/authorize"
    token_url     = "https://id.hauptmann.dev/api/oidc/token"
    certs_url     = "https://id.hauptmann.dev/.well-known/jwks.json"
    scopes        = ["openid", "profile", "email", "groups"]
  }
}

resource "cloudflare_zero_trust_access_policy" "owner_only" {
  account_id = var.cloudflare_account_id
  decision   = "allow"
  name       = "owner-only"

  include = [{
    email = {
      email = var.zero_trust_owner_email
    }
  }]
}

resource "cloudflare_zero_trust_access_application" "sonarr" {
  zone_id              = var.cloudflare_zone_id
  name                 = "Sonarr"
  domain               = "sonarr.hauptmann.dev"
  type                 = "self_hosted"
  session_duration     = "24h"
  app_launcher_visible = false
  allowed_idps         = [cloudflare_zero_trust_access_identity_provider.pocket_id.id]

  policies = [{
    id         = cloudflare_zero_trust_access_policy.owner_only.id
    precedence = 1
  }]
}
