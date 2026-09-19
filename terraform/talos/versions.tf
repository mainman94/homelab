terraform {
  # 1.9 is the floor for `validation` blocks that reference another variable —
  # the cluster_vip / management_ip collision check in variables.tf needs it.
  # The stack deliberately stops short of `ephemeral`, see main.tf.
  required_version = ">= 1.9.0"

  required_providers {
    talos = {
      source = "siderolabs/talos"
      # Pinned to the 0.11 series on purpose, not `~> 0.11`. The provider is
      # pre-1.0, so a minor bump is a breaking change: 0.12 replaces this
      # resource set with `talos_machine` / `talos_cluster`. `~> 0.11` would
      # allow everything below 1.0 and pull that in on the next `init
      # -upgrade`; `~> 0.11.0` allows 0.11.x only.
      version = "~> 0.11.0"
    }
  }
}
