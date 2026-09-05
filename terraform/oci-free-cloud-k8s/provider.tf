terraform {
  required_version = ">= 1.6.0"

  required_providers {
    oci = {
      # ~> 8, not ~> 7: oracle-terraform-modules/vcn/oci v4 requires
      # >= 8.14.0, so the two constraints could not both be satisfied and
      # the stack could not init at all.
      source  = "oracle/oci"
      version = "~> 8"
    }

    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
    }
  }

}

provider "oci" {
  tenancy_ocid = var.tenancy_ocid
  user_ocid    = var.user_ocid
  fingerprint  = var.fingerprint
  private_key  = var.private_key
  region       = var.region
}
