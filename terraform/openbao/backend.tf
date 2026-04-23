terraform {
  required_version = "> 1.14"

  cloud {

    organization = "eggenberg-homelab"

    workspaces {
      name = "openbao"
    }
  }
}