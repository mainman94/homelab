output "issuer_url" {
  description = "Value for contact-api OIDC_ISSUER_URL"
  value       = "${var.keycloak_url}/realms/${keycloak_realm.homelab.realm}"
}

output "notifier_client_id" {
  value = keycloak_openid_client.notifier.client_id
}

# Also in state (sensitive). Read with `terraform output -raw` from a local
# init against the workspace, or in the Keycloak admin console, then store it
# in OpenBao for the notifier (no write path from this stack by design).
output "notifier_client_secret" {
  value     = keycloak_openid_client.notifier.client_secret
  sensitive = true
}
