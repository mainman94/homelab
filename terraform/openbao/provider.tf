terraform {
  required_providers {
    # OpenBao is API-compatible with Vault; the hashicorp/vault provider works
    # unmodified. Swap source to "openbao/openbao" later if desired (drop-in).
    vault = {
      source  = "hashicorp/vault"
      version = "~> 5.0"
    }
  }
}

provider "vault" {
  address = var.vault_address
  # Token supplied via the VAULT_TOKEN env var (HCP sensitive workspace var).
  # Never a Terraform variable -> never persisted in state.
}
