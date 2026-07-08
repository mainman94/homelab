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

# Vault auth via HCP workload identity — set on the `cloudflare` workspace:
#   TFC_VAULT_PROVIDER_AUTH = true
#   TFC_VAULT_ADDR          = https://vault.hauptmann.dev
#   TFC_VAULT_RUN_ROLE      = tfc-cloudflare
provider "vault" {
  address = var.vault_address
}

data "vault_kv_secret_v2" "cloudflare" {
  mount = "homelab"
  name  = "prod/cloudflare"
}

provider "cloudflare" {
  api_token = data.vault_kv_secret_v2.cloudflare.data["API_KEY"]
}
