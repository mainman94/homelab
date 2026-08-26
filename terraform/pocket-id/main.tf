# OIDC client Cloudflare Access uses as its identity provider (see
# cloudflare_zero_trust_access_identity_provider.pocket_id in
# ../cloudflare/zero_trust.tf). Previously created by hand in the Pocket ID
# UI, with the resulting client_id/secret pasted into Vault manually.
resource "pocketid_client" "cloudflare_access" {
  name = "Cloudflare Access"

  callback_urls = [
    "https://${var.cloudflare_access_team_domain}/cdn-cgi/access/callback",
  ]

  is_public    = false
  pkce_enabled = false
}

output "cloudflare_access_client_id" {
  value = pocketid_client.cloudflare_access.id
}

output "cloudflare_access_client_secret" {
  value     = pocketid_client.cloudflare_access.client_secret
  sensitive = true
}
