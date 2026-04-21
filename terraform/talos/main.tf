locals {
  common_patch            = file("${path.module}/${var.common_config_patch_file}")
  schematic               = file("${path.module}/${var.schematic_file}")
  endpoints               = [for _, node in var.controlplane_nodes : node.management_ip]
  network_interface_alias = "lan0"

  controlplane_link_alias_patches = {
    for name, node in var.controlplane_nodes :
    name => trimspace(<<-EOT
      apiVersion: v1alpha1
      kind: LinkAliasConfig
      name: ${local.network_interface_alias}
      selector:
        match: mac(link.permanent_addr) == "${node.interface_mac}"
    EOT
    )
  }

  controlplane_patches = {
    for name, node in var.controlplane_nodes :
    name => yamlencode({
      machine = merge(
        {
          network = merge(
            {
              interfaces = [
                {
                  interface = local.network_interface_alias
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
            },
            try(node.node_name, null) == null ? {} : { hostname = node.node_name }
          )
          install = {
            disk  = node.install_disk
            image = local.install_image
          }
        },
        try(node.data_disk, null) == null ? {} : {
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

resource "talos_image_factory_schematic" "this" {
  schematic = local.schematic
}

resource "talos_machine_secrets" "this" {}

locals {
  install_image = "factory.talos.dev/metal-installer/${talos_image_factory_schematic.this.id}:${var.talos_version}"
}

data "talos_client_configuration" "this" {
  cluster_name         = var.cluster_name
  client_configuration = talos_machine_secrets.this.client_configuration
  endpoints            = local.endpoints
  nodes                = local.endpoints
}

data "talos_machine_configuration" "controlplane" {
  for_each = var.controlplane_nodes

  cluster_name       = var.cluster_name
  cluster_endpoint   = var.cluster_endpoint
  machine_type       = "controlplane"
  machine_secrets    = talos_machine_secrets.this.machine_secrets
  kubernetes_version = var.kubernetes_version

  config_patches = [
    local.common_patch,
    local.controlplane_link_alias_patches[each.key],
    local.controlplane_patches[each.key],
  ]
}

resource "talos_machine_configuration_apply" "controlplane" {
  for_each = var.controlplane_nodes

  client_configuration        = talos_machine_secrets.this.client_configuration
  machine_configuration_input = data.talos_machine_configuration.controlplane[each.key].machine_configuration
  node                        = each.value.management_ip
  apply_mode                  = "auto"
}

resource "talos_machine_bootstrap" "this" {
  node                 = var.controlplane_nodes["cp1"].management_ip
  client_configuration = talos_machine_secrets.this.client_configuration

  depends_on = [
    talos_machine_configuration_apply.controlplane,
  ]
}

resource "talos_cluster_kubeconfig" "this" {
  node                 = var.controlplane_nodes["cp1"].management_ip
  client_configuration = talos_machine_secrets.this.client_configuration

  depends_on = [
    talos_machine_bootstrap.this,
  ]
}
