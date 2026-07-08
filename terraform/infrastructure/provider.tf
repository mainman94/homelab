terraform {
  required_providers {
    b2 = {
      source  = "Backblaze/b2"
      version = "~> 0.12"
    }
    vault = {
      source  = "hashicorp/vault"
      version = "~> 5.0"
    }
  }
}

# Vault auth via HCP workload identity — set on the `backblaze` workspace:
#   TFC_VAULT_PROVIDER_AUTH = true
#   TFC_VAULT_ADDR          = https://vault.hauptmann.dev
#   TFC_VAULT_RUN_ROLE      = tfc-backblaze
provider "vault" {
  address = var.vault_address
}

# Needs an account/bucket-create-capable key (the *_K8S_BACKUP keys are
# bucket-scoped and cannot create buckets). Seed prod/backblaze with:
#   APPLICATION_KEY_ID, APPLICATION_KEY
data "vault_kv_secret_v2" "backblaze" {
  mount = "homelab"
  name  = "prod/backblaze"
}

provider "b2" {
  application_key    = data.vault_kv_secret_v2.backblaze.data["APPLICATION_KEY"]
  application_key_id = data.vault_kv_secret_v2.backblaze.data["APPLICATION_KEY_ID"]
}
