terraform {
  required_providers {
    infisical = {
      source = "Infisical/infisical"
      version = "0.15.60"
    }
  }
}

provider "infisical" {
  auth = {
    universal = {
      client_id     = var.infisical_client_id
      client_secret = var.infisical_client_secret
    }
  }
}