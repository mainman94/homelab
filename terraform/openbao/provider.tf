terraform {
  required_providers {
    vault = {
      source  = "hashicorp/vault"
      version = "~> 5"
    }
  }
}

provider "vault" {
  address         = var.vault_endpoint
  token           = var.vault_token
  skip_tls_verify = var.vault_skip_tls_verify
}
