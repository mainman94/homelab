# Cloudflare Access apps — gate sensitive self-hosted UIs behind identity, on
# top of whatever auth the app itself has. Identity comes from Pocket ID via
# OIDC; the Cilium gateway has no forward-auth of its own, so enforcement
# happens at Cloudflare's edge. This only works while the hostnames stay
# proxied — an unproxied record bypasses Access entirely.

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

  # Multiple include rules are OR'd — any listed address gets in.
  include = [for address in var.zero_trust_owner_emails : {
    email = {
      email = address
    }
  }]
}

# Plain UI apps: whole hostname behind the owner-only policy.
locals {
  access_ui_apps = {
    sonarr = { name = "Sonarr", domain = "sonarr.hauptmann.dev" }
    radarr = { name = "Radarr", domain = "radarr.hauptmann.dev" }
    bazarr = { name = "Bazarr", domain = "bazarr.hauptmann.dev" }
    umami  = { name = "Umami", domain = "umami.hauptmann.dev" }
  }

  # Paths that must stay reachable without a login, because the clients are
  # browsers of anonymous site visitors or machines that cannot do OIDC.
  # Cloudflare matches the most specific app, so these win over the
  # hostname-wide apps above for their prefix only.
  access_public_paths = {
    umami_script  = { name = "Umami script", domain = "umami.hauptmann.dev/script.js" }
    umami_collect = { name = "Umami collect", domain = "umami.hauptmann.dev/api/send" }
  }
}

resource "cloudflare_zero_trust_access_application" "ui" {
  for_each = local.access_ui_apps

  zone_id              = var.cloudflare_zone_id
  name                 = each.value.name
  domain               = each.value.domain
  type                 = "self_hosted"
  session_duration     = "24h"
  app_launcher_visible = false
  allowed_idps         = [cloudflare_zero_trust_access_identity_provider.pocket_id.id]

  policies = [{
    id         = cloudflare_zero_trust_access_policy.owner_only.id
    precedence = 1
  }]
}

moved {
  from = cloudflare_zero_trust_access_application.sonarr
  to   = cloudflare_zero_trust_access_application.ui["sonarr"]
}

# Umami serves the tracking script and the event collection endpoint to every
# visitor of hauptmann.dev (see portfolio/src/layout.tsx). Gating those behind
# Access would redirect anonymous browsers to a login page and kill analytics,
# so they are carved out explicitly. The dashboard itself stays protected.
resource "cloudflare_zero_trust_access_policy" "public_bypass" {
  account_id = var.cloudflare_account_id
  decision   = "bypass"
  name       = "public-bypass"

  include = [{
    everyone = {}
  }]
}

resource "cloudflare_zero_trust_access_application" "public_path" {
  for_each = local.access_public_paths

  zone_id              = var.cloudflare_zone_id
  name                 = each.value.name
  domain               = each.value.domain
  type                 = "self_hosted"
  app_launcher_visible = false

  policies = [{
    id         = cloudflare_zero_trust_access_policy.public_bypass.id
    precedence = 1
  }]
}
