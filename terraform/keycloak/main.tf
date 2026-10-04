resource "keycloak_realm" "homelab" {
  realm        = var.realm_name
  enabled      = true
  display_name = "Homelab"

  ssl_required                = "external"
  registration_allowed        = false
  reset_password_allowed      = false
  login_with_email_allowed    = true
  duplicate_emails_allowed    = false
  access_token_lifespan       = "5m"
  sso_session_idle_timeout    = "30m"
  sso_session_max_lifespan    = "10h"
  access_code_lifespan        = "1m"
  default_signature_algorithm = "RS256"
}

# --- Machine-to-machine: portfolio contact-api -------------------------------
# contact-api is the resource server for PATCH /internal/contact/:id/status.
# It verifies bearer tokens (iss, aud, signature, role) itself, so the client
# only exists to own the client role below; it never logs anyone in.
resource "keycloak_openid_client" "contact_api" {
  realm_id  = keycloak_realm.homelab.id
  client_id = "portfolio-contact-api"
  name      = "Portfolio contact-api (resource server)"
  enabled   = true

  access_type                  = "CONFIDENTIAL"
  standard_flow_enabled        = false
  implicit_flow_enabled        = false
  direct_access_grants_enabled = false
  service_accounts_enabled     = false
}

# Must match OIDC_REQUIRED_ROLE in contact-api (default contact:status-write).
resource "keycloak_role" "contact_status_write" {
  realm_id    = keycloak_realm.homelab.id
  client_id   = keycloak_openid_client.contact_api.id
  name        = "contact:status-write"
  description = "May update the delivery status of a contact request"
}

# Caller: the notifier uses the client-credentials grant.
resource "keycloak_openid_client" "notifier" {
  realm_id  = keycloak_realm.homelab.id
  client_id = "portfolio-notifier"
  name      = "Portfolio notifier (machine client)"
  enabled   = true

  access_type                  = "CONFIDENTIAL"
  standard_flow_enabled        = false
  implicit_flow_enabled        = false
  direct_access_grants_enabled = false
  service_accounts_enabled     = true
}

resource "keycloak_openid_client_service_account_role" "notifier_status_write" {
  realm_id                = keycloak_realm.homelab.id
  service_account_user_id = keycloak_openid_client.notifier.service_account_user_id
  client_id               = keycloak_openid_client.contact_api.id
  role                    = keycloak_role.contact_status_write.name
}

# aud = portfolio-contact-api, which contact-api checks (OIDC_AUDIENCE).
resource "keycloak_openid_audience_protocol_mapper" "notifier_audience" {
  realm_id  = keycloak_realm.homelab.id
  client_id = keycloak_openid_client.notifier.id
  name      = "contact-api-audience"

  included_client_audience = keycloak_openid_client.contact_api.client_id
  add_to_id_token          = false
  add_to_access_token      = true
}
