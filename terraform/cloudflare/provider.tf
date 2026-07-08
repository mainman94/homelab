terraform {
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

provider "cloudflare" {
  api_token = ephemeral.vault_kv_secret_v2.cloudflare.data["API_KEY"]
}
