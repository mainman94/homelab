locals {
  # Keep node ordering stable so the bootstrap node is predictable.
  node_keys = sort(keys(var.nodes))

  bootstrap_node = var.nodes[local.node_keys[0]]

  talos_endpoints = [
    for key in local.node_keys : var.nodes[key].ip
  ]
}

resource "talos_machine_secrets" "this" {}

# Build a talosconfig that can talk to all control plane nodes.
data "talos_client_configuration" "this" {
  cluster_name         = var.cluster_name
  client_configuration = talos_machine_secrets.this.client_configuration
  endpoints            = local.talos_endpoints
  nodes                = local.talos_endpoints
}

# Generate one machine configuration per node so hostname, IP, and disk can differ.
data "talos_machine_configuration" "this" {
  for_each = var.nodes

  cluster_name     = var.cluster_name
  cluster_endpoint = var.cluster_endpoint
  machine_type     = "controlplane"
  machine_secrets  = talos_machine_secrets.this.machine_secrets
  docs             = false
  examples         = false

  config_patches = [
    yamlencode({
      machine = {
        install = {
          disk = each.value.install_disk
        }
        kubelet = {
          extraMounts = [
            {
              destination = var.longhorn_data_path
              type        = "bind"
              source      = var.longhorn_data_path
              options = [
                "bind",
                "rshared",
                "rw",
              ]
            }
          ]
        }
        network = {
          hostname = each.value.hostname
          interfaces = [
            {
              interface = var.network_interface
              addresses = ["${each.value.ip}/24"]
              vip = {
                ip = var.controlplane_vip
              }
            }
          ]
        }
      }
      cluster = {
        apiServer = {
          admissionControl = [
            {
              name = "PodSecurity"
              configuration = {
                apiVersion = "pod-security.admission.config.k8s.io/v1alpha1"
                kind       = "PodSecurityConfiguration"
                defaults = {
                  enforce        = "baseline"
                  enforceVersion = "latest"
                  audit          = "restricted"
                  auditVersion   = "latest"
                  warn           = "restricted"
                  warnVersion    = "latest"
                }
                exemptions = {
                  namespaces = [
                    "kube-system",
                    var.longhorn_namespace,
                  ]
                  runtimeClasses = []
                  usernames      = []
                }
              }
            }
          ]
        }
        proxy = {
          disabled = true
        }
        network = {
          cni = {
            name = "none"
          }
        }
      }
    })
  ]
}

# Apply each generated machine configuration directly to its target node.
resource "talos_machine_configuration_apply" "this" {
  for_each = var.nodes

  client_configuration        = talos_machine_secrets.this.client_configuration
  machine_configuration_input = data.talos_machine_configuration.this[each.key].machine_configuration
  endpoint                    = each.value.ip
  node                        = each.value.ip
}

# Bootstrap etcd exactly once on the first control plane node.
resource "talos_machine_bootstrap" "this" {
  depends_on = [talos_machine_configuration_apply.this]

  client_configuration = talos_machine_secrets.this.client_configuration
  endpoint             = local.bootstrap_node.ip
  node                 = local.bootstrap_node.ip

  lifecycle {
    ignore_changes = all
  }
}

# Retrieve kubeconfig from the bootstrapped control plane node.
resource "talos_cluster_kubeconfig" "this" {
  depends_on = [talos_machine_bootstrap.this]

  client_configuration = talos_machine_secrets.this.client_configuration
  endpoint             = local.bootstrap_node.ip
  node                 = local.bootstrap_node.ip
}
