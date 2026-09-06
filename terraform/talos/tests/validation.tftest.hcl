# Variable validation for the Talos stack.
#
# This stack bootstraps the cluster's control plane: a bad node map here is
# not a failed plan, it is a machine configuration applied to the wrong host.
# The suite uses mock_provider, so it needs no credentials and touches
# nothing — `terraform test` after `terraform init -backend=false`.
#
# `command = plan` throughout: apply would try to reach real machines.

mock_provider "talos" {}

variables {
  cluster_name       = "talos-test"
  cluster_endpoint   = "https://192.168.0.10:6443"
  cluster_vip        = "192.168.0.10"
  gateway            = "192.168.0.2"
  talos_version      = "v1.12.6"
  kubernetes_version = "v1.35.2"

  controlplane_nodes = {
    cp1 = {
      management_ip        = "192.168.0.11"
      node_name            = "cp1"
      install_disk         = "/dev/sdc"
      interface_mac        = "00:11:22:33:44:55"
      address_cidr         = "192.168.0.11/24"
      data_disk            = "/dev/sdb"
      data_disk_mountpoint = "/var/mnt/longhorn"
    }
  }
}

# The happy path has to keep planning, or the rejections below prove nothing.
run "a_single_control_plane_node_plans" {
  command = plan
}

run "three_control_plane_nodes_plan" {
  command = plan

  variables {
    controlplane_nodes = {
      cp1 = {
        management_ip = "192.168.0.11"
        node_name     = "cp1"
        install_disk  = "/dev/sdc"
        interface_mac = "00:11:22:33:44:55"
        address_cidr  = "192.168.0.11/24"
      }
      cp2 = {
        management_ip = "192.168.0.12"
        node_name     = "cp2"
        install_disk  = "/dev/sdc"
        interface_mac = "00:11:22:33:44:56"
        address_cidr  = "192.168.0.12/24"
      }
      cp3 = {
        management_ip = "192.168.0.13"
        node_name     = "cp3"
        install_disk  = "/dev/sdc"
        interface_mac = "00:11:22:33:44:57"
        address_cidr  = "192.168.0.13/24"
      }
    }
  }
}

# cp1 is not just a naming convention: the bootstrap and the kubeconfig both
# key off it, so a map without it plans and then fails half way through.
run "rejects_a_node_map_without_cp1" {
  command = plan

  variables {
    controlplane_nodes = {
      controlplane1 = {
        management_ip = "192.168.0.11"
        node_name     = "cp1"
        install_disk  = "/dev/sdc"
        interface_mac = "00:11:22:33:44:55"
        address_cidr  = "192.168.0.11/24"
      }
    }
  }

  expect_failures = [var.controlplane_nodes]
}

# etcd wants an odd number and this hardware has three machines; four is
# always a mistake rather than a deliberate choice.
run "rejects_more_than_three_control_plane_nodes" {
  command = plan

  variables {
    controlplane_nodes = {
      cp1 = {
        management_ip = "192.168.0.11"
        node_name     = "cp1"
        install_disk  = "/dev/sdc"
        interface_mac = "00:11:22:33:44:55"
        address_cidr  = "192.168.0.11/24"
      }
      cp2 = {
        management_ip = "192.168.0.12"
        node_name     = "cp2"
        install_disk  = "/dev/sdc"
        interface_mac = "00:11:22:33:44:56"
        address_cidr  = "192.168.0.12/24"
      }
      cp3 = {
        management_ip = "192.168.0.13"
        node_name     = "cp3"
        install_disk  = "/dev/sdc"
        interface_mac = "00:11:22:33:44:57"
        address_cidr  = "192.168.0.13/24"
      }
      cp4 = {
        management_ip = "192.168.0.14"
        node_name     = "cp4"
        install_disk  = "/dev/sdc"
        interface_mac = "00:11:22:33:44:58"
        address_cidr  = "192.168.0.14/24"
      }
    }
  }

  expect_failures = [var.controlplane_nodes]
}
