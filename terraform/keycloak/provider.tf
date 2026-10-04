terraform {
  # >= 1.10: this stack uses an `ephemeral` block.
  required_version = ">= 1.10.0"

  required_providers {
    keycloak = {
      source  = "keycloak/keycloak"
      version = "~> 5.9"
    }
    vault = {
      source  = "hashicorp/vault"
      version = "~> 5.0"
    }
  }
}

# Vault auth via HCP workload identity — set on the `keycloak` workspace
# (agent execution, reaches OpenBao on the LAN NodePort):
#   TFC_VAULT_PROVIDER_AUTH = true
#   TFC_VAULT_ADDR          = http://192.168.0.129:30020
#   TFC_VAULT_AUTH_PATH     = tfc
#   TFC_VAULT_RUN_ROLE      = tfc-keycloak
provider "vault" {
  address = var.vault_address
}

# Ephemeral: the admin password is fetched per-run and never written to state.
# It is the bootstrap admin created by the Keycloak operator from the same
# OpenBao path (ExternalSecret keycloak-bootstrap-admin in multi-k8s-infra).
# Keycloak flags bootstrap admins as temporary; once a permanent admin or a
# service-account client exists, point `username`/`password` at that instead.
ephemeral "vault_kv_secret_v2" "keycloak" {
  mount = "homelab"
  name  = "prod/keycloak"
}

provider "keycloak" {
  url       = var.keycloak_url
  realm     = "master"
  client_id = "admin-cli"
  username  = "admin"
  password  = ephemeral.vault_kv_secret_v2.keycloak.data["ADMIN_PASSWORD"]
}
