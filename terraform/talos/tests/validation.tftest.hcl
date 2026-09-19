# Variable validation for the Talos stack.
#
# This stack bootstraps the cluster's control plane: a bad node map here is
# not a failed plan, it is a machine configuration applied to the wrong host.
# The suite uses mock_provider, so it needs no credentials and touches
# nothing — `terraform test` after `terraform init -backend=false`.
#
# `command = plan` throughout: apply would try to reach real machines.
#
# This is also why main.tf does not use the provider's ephemeral resources:
# Terraform cannot mock them, and the first `ephemeral` block in the stack
# takes every run below down with it.

mock_provider "talos" {
  # The schematic's precondition compares what the factory resolved against
  # what was asked for, so the mock has to answer with the real names.
  mock_data "talos_image_factory_extensions_versions" {
    defaults = {
      extensions_info = [
        { name = "siderolabs/iscsi-tools" },
        { name = "siderolabs/nfs-utils" },
        { name = "siderolabs/util-linux-tools" },
      ]
    }
  }
}

variables {
  cluster_name       = "talos-test"
  cluster_endpoint   = "https://192.168.0.10:6443"
  cluster_vip        = "192.168.0.10"
  gateway            = "192.168.0.2"
  talos_version      = "v1.14.1"
  kubernetes_version = "v1.36.4"

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

# Every rejection below is only worth something if the happy path still plans.
run "a_single_control_plane_node_plans" {
  command = plan

  assert {
    condition     = output.talos_endpoints == ["192.168.0.11"]
    error_message = "The Talos endpoints should be the nodes' management IPs."
  }

  assert {
    condition     = join(",", output.system_extensions) == "siderolabs/iscsi-tools,siderolabs/nfs-utils,siderolabs/util-linux-tools"
    error_message = "The schematic should carry the extensions the factory resolved, sorted."
  }
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

  assert {
    condition     = length(output.talos_endpoints) == 3
    error_message = "All three nodes should end up in the Talos endpoint list."
  }
}

# The health gate has to be skippable, or a single node being down blocks
# every other change to the stack.
run "the_health_gate_can_be_turned_off" {
  command = plan

  variables {
    wait_for_cluster_health = false
  }
}

# --- node map shape ---------------------------------------------------------

# cp1 is not just a naming convention: the bootstrap and the kubeconfig both
# key off it, so a map without it plans and then fails half way through.
run "rejects_a_node_map_without_cp1" {
  command = plan

  variables {
    controlplane_nodes = {
      controlplane1 = {
        management_ip = "192.168.0.11"
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
        install_disk  = "/dev/sdc"
        interface_mac = "00:11:22:33:44:55"
        address_cidr  = "192.168.0.11/24"
      }
      cp2 = {
        management_ip = "192.168.0.12"
        install_disk  = "/dev/sdc"
        interface_mac = "00:11:22:33:44:56"
        address_cidr  = "192.168.0.12/24"
      }
      cp3 = {
        management_ip = "192.168.0.13"
        install_disk  = "/dev/sdc"
        interface_mac = "00:11:22:33:44:57"
        address_cidr  = "192.168.0.13/24"
      }
      cp4 = {
        management_ip = "192.168.0.14"
        install_disk  = "/dev/sdc"
        interface_mac = "00:11:22:33:44:58"
        address_cidr  = "192.168.0.14/24"
      }
    }
  }

  expect_failures = [var.controlplane_nodes]
}

# --- per-node fields --------------------------------------------------------

# Talos reports permanent MACs lowercase and LinkAliasConfig compares them as
# strings, so an uppercase MAC never matches: the node boots with no lan0, no
# address and no route, and has to be recovered at the console.
run "rejects_an_uppercase_mac" {
  command = plan

  variables {
    controlplane_nodes = {
      cp1 = {
        management_ip = "192.168.0.11"
        install_disk  = "/dev/sdc"
        interface_mac = "00:11:22:33:44:AA"
        address_cidr  = "192.168.0.11/24"
      }
    }
  }

  expect_failures = [var.controlplane_nodes]
}

run "rejects_a_malformed_mac" {
  command = plan

  variables {
    controlplane_nodes = {
      cp1 = {
        management_ip = "192.168.0.11"
        install_disk  = "/dev/sdc"
        interface_mac = "00-11-22-33-44-55"
        address_cidr  = "192.168.0.11/24"
      }
    }
  }

  expect_failures = [var.controlplane_nodes]
}

# Two nodes on one MAC means the alias on one of them matches the other's NIC.
run "rejects_a_reused_mac" {
  command = plan

  variables {
    controlplane_nodes = {
      cp1 = {
        management_ip = "192.168.0.11"
        install_disk  = "/dev/sdc"
        interface_mac = "00:11:22:33:44:55"
        address_cidr  = "192.168.0.11/24"
      }
      cp2 = {
        management_ip = "192.168.0.12"
        install_disk  = "/dev/sdc"
        interface_mac = "00:11:22:33:44:55"
        address_cidr  = "192.168.0.12/24"
      }
    }
  }

  expect_failures = [var.controlplane_nodes]
}

# Two entries pointing at one machine: the second apply overwrites the first.
run "rejects_a_reused_management_ip" {
  command = plan

  variables {
    controlplane_nodes = {
      cp1 = {
        management_ip = "192.168.0.11"
        install_disk  = "/dev/sdc"
        interface_mac = "00:11:22:33:44:55"
        address_cidr  = "192.168.0.11/24"
      }
      cp2 = {
        management_ip = "192.168.0.11"
        install_disk  = "/dev/sdc"
        interface_mac = "00:11:22:33:44:56"
        address_cidr  = "192.168.0.12/24"
      }
    }
  }

  expect_failures = [var.controlplane_nodes]
}

run "rejects_a_management_ip_that_is_not_an_address" {
  command = plan

  variables {
    controlplane_nodes = {
      cp1 = {
        management_ip = "192.168.0.11/24"
        install_disk  = "/dev/sdc"
        interface_mac = "00:11:22:33:44:55"
        address_cidr  = "192.168.0.11/24"
      }
    }
  }

  expect_failures = [var.controlplane_nodes]
}

run "rejects_an_address_without_a_prefix_length" {
  command = plan

  variables {
    controlplane_nodes = {
      cp1 = {
        management_ip = "192.168.0.11"
        install_disk  = "/dev/sdc"
        interface_mac = "00:11:22:33:44:55"
        address_cidr  = "192.168.0.11"
      }
    }
  }

  expect_failures = [var.controlplane_nodes]
}

run "rejects_an_install_disk_that_is_not_a_device" {
  command = plan

  variables {
    controlplane_nodes = {
      cp1 = {
        management_ip = "192.168.0.11"
        install_disk  = "sdc"
        interface_mac = "00:11:22:33:44:55"
        address_cidr  = "192.168.0.11/24"
      }
    }
  }

  expect_failures = [var.controlplane_nodes]
}

# Installing onto the data disk wipes whatever Longhorn had on it.
run "rejects_an_install_disk_that_is_also_the_data_disk" {
  command = plan

  variables {
    controlplane_nodes = {
      cp1 = {
        management_ip = "192.168.0.11"
        install_disk  = "/dev/sdb"
        interface_mac = "00:11:22:33:44:55"
        address_cidr  = "192.168.0.11/24"
        data_disk     = "/dev/sdb"
      }
    }
  }

  expect_failures = [var.controlplane_nodes]
}

# Talos only mounts user partitions below /var; anywhere else is dropped at
# boot without a word and Longhorn silently writes to the system disk.
run "rejects_a_mountpoint_outside_var_mnt" {
  command = plan

  variables {
    controlplane_nodes = {
      cp1 = {
        management_ip        = "192.168.0.11"
        install_disk         = "/dev/sdc"
        interface_mac        = "00:11:22:33:44:55"
        address_cidr         = "192.168.0.11/24"
        data_disk            = "/dev/sdb"
        data_disk_mountpoint = "/mnt/longhorn"
      }
    }
  }

  expect_failures = [var.controlplane_nodes]
}

# --- cluster-level values ---------------------------------------------------

# The VIP floats between nodes. Handing it to one of them as a static address
# means two hosts answer for it and the API endpoint flaps.
run "rejects_a_vip_that_is_also_a_node_address" {
  command = plan

  variables {
    cluster_vip = "192.168.0.11"
  }

  expect_failures = [var.controlplane_nodes]
}

run "rejects_a_vip_with_a_prefix_length" {
  command = plan

  variables {
    cluster_vip = "192.168.0.10/24"
  }

  expect_failures = [var.cluster_vip]
}

run "rejects_a_gateway_that_is_not_an_address" {
  command = plan

  variables {
    gateway = "192.168.0.0/24"
  }

  expect_failures = [var.gateway]
}

run "rejects_a_plaintext_cluster_endpoint" {
  command = plan

  variables {
    cluster_endpoint = "http://192.168.0.10:6443"
  }

  expect_failures = [var.cluster_endpoint]
}

run "rejects_a_cluster_endpoint_without_a_port" {
  command = plan

  variables {
    cluster_endpoint = "https://192.168.0.10"
  }

  expect_failures = [var.cluster_endpoint]
}

# A bare "1.14.1" is accepted by the factory for some paths and not others;
# requiring the tag form keeps the installer image and the config contract
# spelled the same way everywhere.
run "rejects_a_talos_version_without_the_v_prefix" {
  command = plan

  variables {
    talos_version = "1.14.1"
  }

  expect_failures = [var.talos_version]
}

run "rejects_a_kubernetes_minor_without_a_patch" {
  command = plan

  variables {
    kubernetes_version = "v1.36"
  }

  expect_failures = [var.kubernetes_version]
}

# --- image factory ----------------------------------------------------------

run "rejects_a_duplicate_system_extension" {
  command = plan

  variables {
    system_extensions = ["siderolabs/iscsi-tools", "siderolabs/iscsi-tools"]
  }

  expect_failures = [var.system_extensions]
}

run "rejects_an_unqualified_system_extension" {
  command = plan

  variables {
    system_extensions = ["iscsi-tools"]
  }

  expect_failures = [var.system_extensions]
}

# An exact filter that matches nothing returns nothing rather than failing, so
# the schematic would otherwise be built without the extension.
run "rejects_an_extension_the_factory_does_not_publish" {
  command = plan

  variables {
    system_extensions = ["siderolabs/iscsi-tools", "siderolabs/does-not-exist"]
  }

  expect_failures = [talos_image_factory_schematic.this]
}
