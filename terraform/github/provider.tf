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
# on the `github` workspace (no static VAULT_TOKEN, no Infisical varset):
#   TFC_VAULT_PROVIDER_AUTH = true
#   TFC_VAULT_ADDR          = https://vault.hauptmann.dev
#   TFC_VAULT_RUN_ROLE      = tfc-github
# HCP injects a short-lived VAULT_TOKEN for the run; only the address is set here.
provider "vault" {
  address = var.vault_address
}

data "vault_kv_secret_v2" "github" {
  mount = "homelab"
  name  = "prod/github"
}

provider "github" {
  token = data.vault_kv_secret_v2.github.data["PAT"]
  owner = var.github_owner
}
