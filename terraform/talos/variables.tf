# Cluster identity ------------------------------------------------------------

variable "cluster_name" {
  description = "Talos/Kubernetes cluster name."
  type        = string
  default     = "talos-bm"

  validation {
    condition     = can(regex("^[a-z0-9]([-a-z0-9]*[a-z0-9])?$", var.cluster_name))
    error_message = "cluster_name must be a lowercase DNS label: letters, digits and hyphens, not starting or ending with a hyphen."
  }
}

variable "cluster_endpoint" {
  description = "Kubernetes API endpoint, including scheme and port (e.g. https://192.168.0.10:6443)."
  type        = string

  validation {
    condition     = can(regex("^https://[^/]+:[0-9]+$", var.cluster_endpoint))
    error_message = "cluster_endpoint must be an https:// URL with an explicit port and no path, e.g. https://192.168.0.10:6443."
  }
}

variable "cluster_vip" {
  description = "Virtual IP shared by the control plane nodes. Must be a free address on the node subnet — Talos claims it, nothing else may."
  type        = string

  validation {
    condition     = can(cidrnetmask("${var.cluster_vip}/32"))
    error_message = "cluster_vip must be a single IPv4 address, without a prefix length."
  }
}

variable "gateway" {
  description = "Default IPv4 gateway for all nodes."
  type        = string

  validation {
    condition     = can(cidrnetmask("${var.gateway}/32"))
    error_message = "gateway must be a single IPv4 address, without a prefix length."
  }
}

# Versions --------------------------------------------------------------------

variable "talos_version" {
  description = <<-EOT
    Talos version for the Image Factory installer image, which
    `talos_machine.image` rolls out to running nodes on apply — see
    "Upgrading Talos" in readme.md.
  EOT
  type        = string
  default     = "v1.14.1"

  validation {
    condition     = can(regex("^v[0-9]+[.][0-9]+[.][0-9]+$", var.talos_version))
    error_message = "talos_version must be a full release tag with a leading v, e.g. v1.14.1."
  }
}

variable "machine_config_contract" {
  description = <<-EOT
    Version contract the base machine configuration is generated against,
    separate from `talos_version` on purpose. A 1.14 contract generates the
    multi-document config (KubePrismConfig, KubeProxyConfig,
    UnattendedInstallConfig, ...), which Talos refuses alongside the v1alpha1
    fields patch.yaml still sets, and which has no replacement for
    `cluster.allowSchedulingOnControlPlanes` — so it stays on 1.13 until the
    patches move to the new documents. Only major.minor matters.
  EOT
  type        = string
  default     = "v1.13.0"

  validation {
    condition     = can(regex("^v[0-9]+[.][0-9]+[.][0-9]+$", var.machine_config_contract))
    error_message = "machine_config_contract must be a full release tag with a leading v, e.g. v1.13.0."
  }
}

variable "kubernetes_version" {
  description = "Target Kubernetes version. Applied by `terraform apply`, so treat a minor bump as a cluster upgrade."
  type        = string
  default     = "v1.36.4"

  validation {
    condition     = can(regex("^v[0-9]+[.][0-9]+[.][0-9]+$", var.kubernetes_version))
    error_message = "kubernetes_version must be a full release tag with a leading v, e.g. v1.36.4."
  }
}

# Image Factory ---------------------------------------------------------------

variable "system_extensions" {
  description = <<-EOT
    Official Image Factory extensions baked into the installer, by their
    factory name (`siderolabs/<extension>`). Every entry is resolved against
    the factory for `talos_version` at plan time; an entry that does not exist
    for that version fails the plan instead of producing a schematic silently
    missing it.
  EOT
  type        = list(string)
  default = [
    "siderolabs/iscsi-tools",     # Longhorn and other iSCSI-backed storage
    "siderolabs/nfs-utils",       # NFS mounts
    "siderolabs/util-linux-tools" # fstrim and friends, wanted by Longhorn
  ]

  validation {
    condition     = length(var.system_extensions) == length(toset(var.system_extensions))
    error_message = "system_extensions must not contain duplicates."
  }

  validation {
    condition     = alltrue([for e in var.system_extensions : can(regex("^[a-z0-9-]+/[a-z0-9-]+$", e))])
    error_message = "Each system extension must be a factory name of the form vendor/extension, e.g. siderolabs/iscsi-tools."
  }
}

variable "architecture" {
  description = "CPU architecture of the bare-metal nodes, used for the Image Factory assets."
  type        = string
  default     = "amd64"

  validation {
    condition     = contains(["amd64", "arm64"], var.architecture)
    error_message = "architecture must be amd64 or arm64."
  }
}

# Config patches --------------------------------------------------------------

variable "common_config_patch_file" {
  description = "Path to the shared Talos config patch, relative to this module."
  type        = string
  default     = "patch.yaml"
}

variable "network_interface_alias" {
  description = "Stable link alias bound to each node's NIC by MAC, so the config does not depend on kernel device naming."
  type        = string
  default     = "lan0"

  validation {
    condition     = can(regex("^[a-z][a-z0-9]{0,14}$", var.network_interface_alias))
    error_message = "network_interface_alias must be a short lowercase interface name, e.g. lan0."
  }
}

# Health gate -----------------------------------------------------------------

variable "wait_for_cluster_health" {
  description = <<-EOT
    Block on a Talos health check between bootstrap and fetching the
    kubeconfig. Set to false when a node is deliberately down and you still
    need to plan or apply the rest of the stack.
  EOT
  type        = bool
  default     = true
}

variable "cluster_health_timeout" {
  description = "How long the health check waits for the control plane to settle."
  type        = string
  default     = "10m"

  validation {
    condition     = can(regex("^[0-9]+(s|m|h)$", var.cluster_health_timeout))
    error_message = "cluster_health_timeout must be a Go duration such as 30s, 10m or 1h."
  }
}

# Nodes -----------------------------------------------------------------------

variable "controlplane_nodes" {
  description = "Bare-metal control plane nodes. Start with cp1, then add cp2 and cp3 over time."
  type = map(object({
    management_ip        = string
    node_name            = optional(string)
    install_disk         = string
    interface_mac        = string
    address_cidr         = string
    data_disk            = optional(string)
    data_disk_mountpoint = optional(string, "/var/mnt/longhorn")
  }))

  validation {
    condition     = contains(keys(var.controlplane_nodes), "cp1")
    error_message = "controlplane_nodes must contain at least the cp1 entry."
  }

  validation {
    condition     = length(var.controlplane_nodes) >= 1 && length(var.controlplane_nodes) <= 3
    error_message = "controlplane_nodes must contain between 1 and 3 nodes."
  }

  validation {
    condition     = alltrue([for n in var.controlplane_nodes : can(cidrnetmask("${n.management_ip}/32"))])
    error_message = "Every management_ip must be a single IPv4 address, without a prefix length."
  }

  validation {
    condition     = alltrue([for n in var.controlplane_nodes : can(cidrnetmask(n.address_cidr))])
    error_message = "Every address_cidr must be an IPv4 address with a prefix length, e.g. 192.168.0.11/24."
  }

  # Talos reports permanent MACs lowercase and LinkAliasConfig compares them
  # with a case-sensitive CEL string equality. An uppercase MAC here parses
  # fine, never matches, and the node boots with no lan0 and no network.
  validation {
    condition     = alltrue([for n in var.controlplane_nodes : can(regex("^([0-9a-f]{2}:){5}[0-9a-f]{2}$", n.interface_mac))])
    error_message = "Every interface_mac must be a lowercase colon-separated MAC address, e.g. 80:ce:62:2a:c2:32."
  }

  validation {
    condition     = alltrue([for n in var.controlplane_nodes : startswith(n.install_disk, "/dev/")])
    error_message = "Every install_disk must be an absolute /dev path. Prefer a stable /dev/disk/by-id/... identifier."
  }

  validation {
    condition     = alltrue([for n in var.controlplane_nodes : n.data_disk == null || startswith(coalesce(n.data_disk, "/dev/"), "/dev/")])
    error_message = "Every data_disk must be an absolute /dev path. Prefer a stable /dev/disk/by-id/... identifier."
  }

  # Talos only mounts user partitions below /var; anything else is silently
  # ignored at boot.
  validation {
    condition     = alltrue([for n in var.controlplane_nodes : startswith(n.data_disk_mountpoint, "/var/mnt/")])
    error_message = "Every data_disk_mountpoint must live under /var/mnt/."
  }

  validation {
    condition     = alltrue([for n in var.controlplane_nodes : n.data_disk == null || n.install_disk != coalesce(n.data_disk, "")])
    error_message = "install_disk and data_disk must be different devices — Talos would otherwise wipe the data disk on install."
  }

  validation {
    condition = length([for n in var.controlplane_nodes : n.management_ip]) == length(distinct([
      for n in var.controlplane_nodes : n.management_ip
    ]))
    error_message = "Every node needs its own management_ip."
  }

  validation {
    condition = length([for n in var.controlplane_nodes : n.address_cidr]) == length(distinct([
      for n in var.controlplane_nodes : n.address_cidr
    ]))
    error_message = "Every node needs its own address_cidr."
  }

  validation {
    condition = length([for n in var.controlplane_nodes : n.interface_mac]) == length(distinct([
      for n in var.controlplane_nodes : n.interface_mac
    ]))
    error_message = "Every node needs its own interface_mac — two nodes sharing one means the alias matches the wrong host."
  }

  # The VIP floats between the nodes; handing it out as a node address as well
  # means two hosts answer for it and the API endpoint flaps.
  validation {
    condition     = !contains([for n in var.controlplane_nodes : n.management_ip], var.cluster_vip)
    error_message = "cluster_vip must not be one of the management_ip values — it is a floating address, not a node address."
  }

  validation {
    condition     = !contains([for n in var.controlplane_nodes : split("/", n.address_cidr)[0]], var.cluster_vip)
    error_message = "cluster_vip must not be one of the address_cidr addresses — it is a floating address, not a node address."
  }
}
