terraform {
  required_version = ">= 1.10.0"

  required_providers {
    tfe = {
      source  = "hashicorp/tfe"
      version = "~> 0.84"
    }
  }
}

provider "tfe" {
  # Authenticates via TFE_TOKEN environment variable (or Terraform Cloud execution context)
}
