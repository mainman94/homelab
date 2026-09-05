terraform {
  required_version = ">= 1.6.0"

  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 5"
    }
    vault = {
      source  = "hashicorp/vault"
      version = "~> 5.0"
    }
  }
}

# Vault auth via HCP workload identity — set on the `cloudflare` workspace
# (agent execution, reaches OpenBao on the LAN NodePort):
#   TFC_VAULT_PROVIDER_AUTH = true
#   TFC_VAULT_ADDR          = http://192.168.0.129:30020
#   TFC_VAULT_AUTH_PATH     = tfc
#   TFC_VAULT_RUN_ROLE      = tfc-cloudflare
provider "vault" {
  address = var.vault_address
}

# Ephemeral: the API token is fetched per-run and never written to state.
ephemeral "vault_kv_secret_v2" "cloudflare" {
  mount = "homelab"
  name  = "prod/cloudflare"
}

# Not ephemeral: the identity provider resource persists client_secret to
# state regardless (not a write-only attribute), so there's no benefit to
# fetching it ephemerally.
data "vault_kv_secret_v2" "pocket_id_access" {
  mount = "homelab"
  name  = "prod/pocket-id-cloudflare-access"
}

# Not ephemeral: the IP ends up in state as the A-record content anyway. Kept in
# its own KV path rather than `prod/cloudflare` so reading it as a data source
# does not persist that path's API token to state.
data "vault_kv_secret_v2" "network" {
  mount = "homelab"
  name  = "prod/network"
}

provider "cloudflare" {
  api_token = ephemeral.vault_kv_secret_v2.cloudflare.data["API_KEY"]
}
