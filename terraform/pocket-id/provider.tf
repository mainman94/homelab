terraform {
  required_providers {
    pocketid = {
      source  = "Trozz/pocketid"
      version = "~> 2.0"
    }
    vault = {
      source  = "hashicorp/vault"
      version = "~> 5.0"
    }
  }
}

# Vault auth via HCP workload identity — set on the `pocket-id` workspace
# (agent execution, reaches OpenBao on the LAN NodePort):
#   TFC_VAULT_PROVIDER_AUTH = true
#   TFC_VAULT_ADDR          = http://192.168.0.129:30020
#   TFC_VAULT_AUTH_PATH     = tfc
#   TFC_VAULT_RUN_ROLE      = tfc-pocket-id
provider "vault" {
  address = var.vault_address
}

# Ephemeral: the API token is fetched per-run and never written to state.
ephemeral "vault_kv_secret_v2" "pocket_id" {
  mount = "homelab"
  name  = "prod/pocket-id"
}

provider "pocketid" {
  base_url  = var.pocket_id_base_url
  api_token = ephemeral.vault_kv_secret_v2.pocket_id.data["API_TOKEN"]
}
