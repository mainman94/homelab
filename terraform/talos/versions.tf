terraform {
  # 1.9 is the floor for `validation` blocks that reference another variable —
  # the cluster_vip / management_ip collision check in variables.tf needs it.
  # The stack deliberately stops short of `ephemeral`, see main.tf.
  required_version = ">= 1.9.0"

  required_providers {
    talos = {
      source = "siderolabs/talos"
      # Pinned to the 0.12 series on purpose, not `~> 0.12`. The provider is
      # pre-1.0, so a minor bump is a breaking change. Resources here still
      # use the pre-0.12 schema (talos_machine_secrets, ..._configuration_apply,
      # ..._bootstrap, talos_cluster_kubeconfig); 0.12 kept them working but
      # introduces talos_machine / talos_cluster as their replacement —
      # migrating is separate follow-up work, not done by this bump.
      version = "~> 0.12.0"
    }
  }
}
