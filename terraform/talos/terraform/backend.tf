terraform {
  backend "remote" {
    hostname     = "app.terraform.io"
    organization = "eggenberg-homelab"

    workspaces {
      name = "eggenberg-talos-cluster"
    }
  }
}
