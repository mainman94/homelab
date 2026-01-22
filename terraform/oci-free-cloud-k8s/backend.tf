terraform {
  backend "remote" {
    hostname     = "app.terraform.io"
    organization = "eggenberg-homelab"

    workspaces {
      name = "oci-free-cloud-k8s"
    }
  }
}
