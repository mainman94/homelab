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
#
# On `talos_cluster`: provider 0.12 also adds this resource, which folds
# bootstrap and health-gating into one. Not adopted here — it's new in this
# same release with no documented `terraform import` path (unlike
# talos_machine_bootstrap below, which explicitly supports importing an
# already-bootstrapped node). Adding it fresh to state on an already-live
# cluster risks it calling the bootstrap API again on create. `talos_machine`
# below doesn't have that risk (config-apply is idempotent by design), which
# is why it moved and this didn't.
#
# On parallelism: `talos_machine` has no equivalent to the old
# `apply_mode = "staged_if_needing_reboot"`. A config change that needs a
# reboot applies — and reboots — immediately, no staging. Combined with
# `for_each` over up to three control-plane nodes, a default `terraform
# apply` (parallelism 10) could reboot all three at once and take etcd
# quorum with it. Always run this stack's applies with `-parallelism=1`.

resource "talos_machine_secrets" "this" {
  talos_version = var.talos_version
}

data "talos_client_configuration" "this" {
  cluster_name         = var.cluster_name
  client_configuration = talos_machine_secrets.this.client_configuration
  endpoints            = local.endpoints
  nodes                = local.endpoints
}

resource "talos_machine" "controlplane" {
  for_each = var.controlplane_nodes

  node                  = each.value.management_ip
  client_configuration  = talos_machine_secrets.this.client_configuration
  machine_configuration = data.talos_machine_configuration.controlplane[each.key].machine_configuration

  # Same value already baked into the UnattendedInstallConfig in config.tf's
  # controlplane_install_patches. Setting it here too is what makes a talos_version /
  # system_extensions bump actually upgrade the running OS on the next
  # `terraform apply`, instead of only changing what a fresh install would
  # use — this is the Terraform-driven upgrade path; see "Upgrading Talos" in
  # readme.md.
  image = local.install_image

  # `true` needs a kubeconfig, and wiring
  # talos_cluster_kubeconfig.this.kubeconfig_raw in here would create
  # talos_machine -> talos_cluster_kubeconfig -> talos_machine_bootstrap ->
  # talos_machine, a dependency cycle Terraform refuses outright. Revisit if
  # talos_cluster is ever adopted and the graph is restructured around it.
  drain_on_upgrade = false
}

resource "talos_machine_bootstrap" "this" {
  node                 = var.controlplane_nodes["cp1"].management_ip
  client_configuration = talos_machine_secrets.this.client_configuration

  depends_on = [
    talos_machine.controlplane,
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
