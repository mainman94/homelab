# Cluster lifecycle: secrets, config apply, bootstrap, health gate, kubeconfig.
#
# On `ephemeral`: provider 0.11 adds ephemeral variants of
# talos_machine_configuration / _client_configuration / _cluster_kubeconfig,
# and write-only `*_wo` arguments to feed them into. This stack stays on the
# data-source form on purpose. The state already holds
# `talos_machine_secrets` — every CA key, the bootstrap token, the encryption
# secrets — because that resource has to persist, so routing the *rendered*
# config around state removes a copy of material that is in there either way.
# The cost is not hypothetical: `terraform test` cannot mock ephemeral
# resources ("No ephemeral resource types in mock providers"), so the whole
# tests/ suite below stops running the moment an ephemeral block appears —
# the same wall the `github` stack hit, documented in AGENTS.md. Guarding
# against a machine configuration going to the wrong host is worth more here
# than de-duplicating a secret. Revisit when Terraform can mock ephemerals.

resource "talos_machine_secrets" "this" {
  talos_version = var.talos_version
}

data "talos_client_configuration" "this" {
  cluster_name         = var.cluster_name
  client_configuration = talos_machine_secrets.this.client_configuration
  endpoints            = local.endpoints
  nodes                = local.endpoints
}

resource "talos_machine_configuration_apply" "controlplane" {
  for_each = var.controlplane_nodes

  client_configuration        = talos_machine_secrets.this.client_configuration
  machine_configuration_input = data.talos_machine_configuration.controlplane[each.key].machine_configuration
  node                        = each.value.management_ip

  # Dry-runs the change and only stages it when it would need a reboot, so an
  # unrelated edit cannot cycle all three control plane nodes mid-apply.
  # Staged changes land on the next reboot, which for this cluster means the
  # next `talosctl upgrade`.
  apply_mode = "staged_if_needing_reboot"
}

resource "talos_machine_bootstrap" "this" {
  node                 = var.controlplane_nodes["cp1"].management_ip
  client_configuration = talos_machine_secrets.this.client_configuration

  depends_on = [
    talos_machine_configuration_apply.controlplane,
  ]
}

# Gate between bootstrap and the kubeconfig: etcd and the API server need to be
# up before the kubeconfig is worth anything.
#
# skip_kubernetes_checks is on because this cluster ships `cni: none` and
# `proxy.disabled`. Cilium is installed out of band after the first apply, so
# the Kubernetes-level checks cannot pass on a fresh cluster and would do
# nothing but burn the timeout.
data "talos_cluster_health" "this" {
  count = var.wait_for_cluster_health ? 1 : 0

  client_configuration   = talos_machine_secrets.this.client_configuration
  endpoints              = local.endpoints
  control_plane_nodes    = local.endpoints
  skip_kubernetes_checks = true

  timeouts = {
    read = var.cluster_health_timeout
  }

  depends_on = [
    talos_machine_bootstrap.this,
  ]
}

resource "talos_cluster_kubeconfig" "this" {
  node                 = var.controlplane_nodes["cp1"].management_ip
  client_configuration = talos_machine_secrets.this.client_configuration

  depends_on = [
    talos_machine_bootstrap.this,
    data.talos_cluster_health.this,
  ]
}
