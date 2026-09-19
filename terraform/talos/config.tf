# Machine configuration: the shared patch, the per-node patches, and the
# generated controlplane configuration.
#
# On config document formats: Talos 1.14 deprecates most of the v1alpha1
# `machine:` / `cluster:` tree in favour of single-purpose documents
# (KubeSchedulerConfig, EtcFileConfig, SysctlConfig, UnattendedInstall, ...).
# This stack cannot use them yet. `terraform-provider-talos` 0.11.0 embeds the
# Talos machinery v1.13 SDK, and it parses every config patch before sending
# it, so a 1.14-only document fails the apply with
# `error decoding document v1alpha1/<Kind>/` — the nodes never see it. What
# 1.13 does know, and what this stack therefore uses, is LinkAliasConfig,
# NetworkRuleConfig, TimeSyncConfig, UserVolumeConfig and VolumeConfig. The
# rest stays on the deprecated-but-supported v1alpha1 fields until the
# provider ships a 1.14 SDK; see readme.md.

locals {
  common_patch = file("${path.module}/${var.common_config_patch_file}")

  # The Talos API listens on each node, not on the VIP: the VIP follows the
  # Kubernetes API server, and talking to it for machine operations would hit
  # whichever node happens to hold it.
  endpoints = [for _, node in var.controlplane_nodes : node.management_ip]

  install_image = data.talos_image_factory_urls.this.urls.installer

  # Binds the alias to the NIC by permanent MAC, so the config survives the
  # kernel renaming enp3s0 to enp4s0 after a hardware change.
  controlplane_link_alias_patches = {
    for name, node in var.controlplane_nodes :
    name => trimspace(<<-EOT
      apiVersion: v1alpha1
      kind: LinkAliasConfig
      name: ${var.network_interface_alias}
      selector:
        match: mac(link.permanent_addr) == "${node.interface_mac}"
    EOT
    )
  }

  # The generated base config already carries a HostnameConfig document with
  # `auto: stable`, and Talos 1.14 rejects a config that also sets the
  # v1alpha1 `machine.network.hostname` ("static hostname is already set in
  # v1alpha1 config"). Patching the document is the way to a static hostname,
  # and `auto` has to be turned off explicitly in the same patch: documents
  # merge field by field, so leaving it out keeps `auto: stable` and trips
  # "auto and hostname cannot be set at the same time" instead.
  controlplane_hostname_patches = {
    for name, node in var.controlplane_nodes :
    name => node.node_name == null ? "" : trimspace(<<-EOT
      apiVersion: v1alpha1
      kind: HostnameConfig
      auto: "off"
      hostname: ${node.node_name}
    EOT
    )
  }

  controlplane_patches = {
    for name, node in var.controlplane_nodes :
    name => yamlencode({
      machine = merge(
        {
          network = {
            interfaces = [
              {
                interface = var.network_interface_alias
                dhcp      = false
                addresses = [node.address_cidr]
                routes = [
                  {
                    network = "0.0.0.0/0"
                    gateway = var.gateway
                  }
                ]
                vip = {
                  ip = var.cluster_vip
                }
              }
            ]
          }
          install = {
            disk  = node.install_disk
            image = local.install_image
          }
        },
        # Deprecated in Talos 1.14 in favour of UserVolumeConfig, and kept
        # deliberately: UserVolumeConfig provisions a `u-<name>` labelled
        # partition, which is not the on-disk layout `machine.disks` produced.
        # Switching in place reformats the disk and destroys whatever Longhorn
        # has on it. readme.md has the migration.
        node.data_disk == null ? {} : {
          disks = [
            {
              device = node.data_disk
              partitions = [
                {
                  mountpoint = node.data_disk_mountpoint
                }
              ]
            }
          ]
        }
      )
    })
  }
}

data "talos_machine_configuration" "controlplane" {
  for_each = var.controlplane_nodes

  cluster_name       = var.cluster_name
  cluster_endpoint   = var.cluster_endpoint
  machine_type       = "controlplane"
  machine_secrets    = talos_machine_secrets.this.machine_secrets
  kubernetes_version = var.kubernetes_version

  # The version contract the base config is generated against. Left unset, the
  # provider generates against whatever its bundled SDK defaults to, so a
  # provider upgrade silently switches on new machine-config features and
  # rewrites the config of every node. Tying it to the version actually being
  # installed makes that an explicit, reviewable change.
  talos_version = var.talos_version

  config_patches = compact([
    local.common_patch,
    local.controlplane_link_alias_patches[each.key],
    local.controlplane_hostname_patches[each.key],
    local.controlplane_patches[each.key],
  ])
}
