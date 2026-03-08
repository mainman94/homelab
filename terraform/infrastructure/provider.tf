terraform {
  required_providers {
    b2 = {
      source  = "Backblaze/b2"
      version = "~> 0.12"
    }
  }
}

provider "b2" {
  application_key    = var.APPLICATION_KEY
  application_key_id = var.APPLICATION_KEY_ID
}
