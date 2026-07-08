terraform {
  required_providers {
    github = {
      source  = "integrations/github"
      version = "~> 6.0"
    }
    vault = {
      source  = "hashicorp/vault"
      version = "~> 5.0"
    }
  }
}

# Vault auth is handled by HCP Terraform workload identity — set these env vars
# on the `github` workspace (agent execution, reaches OpenBao on the LAN
# NodePort; no static VAULT_TOKEN, no Infisical varset):
#   TFC_VAULT_PROVIDER_AUTH = true
#   TFC_VAULT_ADDR          = http://192.168.0.129:30020
#   TFC_VAULT_AUTH_PATH     = tfc
#   TFC_VAULT_RUN_ROLE      = tfc-github
# HCP injects a short-lived VAULT_TOKEN for the run; only the address is set here.
provider "vault" {
  address = var.vault_address
}

# Ephemeral: the PAT is fetched per-run and never written to state.
ephemeral "vault_kv_secret_v2" "github" {
  mount = "homelab"
  name  = "prod/github"
}

provider "github" {
  token = ephemeral.vault_kv_secret_v2.github.data["PAT"]
  owner = var.github_owner
}
