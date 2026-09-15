terraform {
  # >= 1.10: this stack uses an `ephemeral` block.
  required_version = ">= 1.10.0"

  required_providers {
    signalfx = {
      source  = "splunk-terraform/signalfx"
      version = "~> 9.0"
    }
    vault = {
      source  = "hashicorp/vault"
      version = "~> 5.0"
    }
  }
}

# Vault auth via HCP workload identity — set on the `splunk` workspace
# (agent execution, reaches OpenBao on the LAN NodePort):
#   TFC_VAULT_PROVIDER_AUTH = true
#   TFC_VAULT_ADDR          = http://192.168.0.129:30020
#   TFC_VAULT_AUTH_PATH     = tfc
#   TFC_VAULT_RUN_ROLE      = tfc-splunk
provider "vault" {
  address = var.vault_address
}

# Ephemeral: the API token is fetched per-run and never written to state.
# Needs an org token with the "API" permission, created under Settings ->
# Access Tokens in Splunk Observability Cloud, stored as ADMIN_ACCESS_TOKEN
# — the ingest-only token used by splunk-otel-collector (ACCESS_TOKEN) does
# not have this permission.
ephemeral "vault_kv_secret_v2" "splunk" {
  mount = "homelab"
  name  = "prod/splunk"
}

provider "signalfx" {
  auth_token = ephemeral.vault_kv_secret_v2.splunk.data["ADMIN_ACCESS_TOKEN"]
  api_url    = "https://api.${var.splunk_realm}.signalfx.com"
}
