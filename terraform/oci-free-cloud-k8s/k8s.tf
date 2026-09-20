resource "oci_containerengine_cluster" "k8s_cluster" {
  compartment_id     = var.compartment_id
  kubernetes_version = var.kubernetes_version
  name               = "k8s-cluster"
  vcn_id             = module.vcn.vcn_id
  endpoint_config {
    is_public_ip_enabled = true
    subnet_id            = oci_core_subnet.vcn_public_subnet.id
  }
  options {
    add_ons {
      is_kubernetes_dashboard_enabled = false
      is_tiller_enabled               = false
    }
    kubernetes_network_config {
      pods_cidr     = "10.244.0.0/16"
      services_cidr = "10.96.0.0/16"
    }
    service_lb_subnet_ids = [oci_core_subnet.vcn_public_subnet.id]
  }
}

data "oci_containerengine_cluster_kube_config" "k8s_cluster_kube_config" {
  #Required
  cluster_id = oci_containerengine_cluster.k8s_cluster.id
}

resource "local_file" "kube_config" {
  # Both pools: the kubeconfig is only useful once every node pool the
  # cluster is meant to have exists.
  depends_on = [
    oci_containerengine_node_pool.k8s_node_pool,
  ]
  content         = data.oci_containerengine_cluster_kube_config.k8s_cluster_kube_config.content
  filename        = "../.kube.config"
  file_permission = 0400
}

data "oci_identity_availability_domains" "ads" {
  compartment_id = var.compartment_id
}

data "oci_core_images" "oracle_linux_arm" {
  compartment_id           = var.compartment_id
  operating_system         = "Oracle Linux"
  operating_system_version = "8"
  shape                    = "VM.Standard.A1.Flex"
  sort_by                  = "TIMECREATED"
  sort_order               = "DESC"
}

# One single-node pool per availability domain, for HA across ADs. The two
# pools were identical apart from the name and which AD they land in, so the
# index is the only thing that varies: pool N sits in availability domain N.
#
# One node per pool on purpose — the Always Free tier allows four A1 OCPUs and
# 24 GB in total, which is exactly two of these.
resource "oci_containerengine_node_pool" "k8s_node_pool" {
  for_each = toset(["1", "2"])

  cluster_id         = oci_containerengine_cluster.k8s_cluster.id
  compartment_id     = var.compartment_id
  kubernetes_version = var.kubernetes_version
  name               = "k8s-node-pool-${each.key}"

  node_config_details {
    placement_configs {
      availability_domain = data.oci_identity_availability_domains.ads.availability_domains[tonumber(each.key) - 1].name
      subnet_id           = oci_core_subnet.vcn_private_subnet.id
    }

    size = 1
  }

  node_shape = "VM.Standard.A1.Flex"

  node_shape_config {
    memory_in_gbs = 6
    ocpus         = 2
  }

  node_source_details {
    source_type = "image"
    image_id    = data.oci_core_images.oracle_linux_arm.images[0].id
  }

  initial_node_labels {
    key   = "name"
    value = "k8s-cluster"
  }
}

# The two pools already exist under their old addresses; this keeps them in
# place instead of destroying and recreating every node.
moved {
  from = oci_containerengine_node_pool.k8s_node_pool_1
  to   = oci_containerengine_node_pool.k8s_node_pool["1"]
}

moved {
  from = oci_containerengine_node_pool.k8s_node_pool_2
  to   = oci_containerengine_node_pool.k8s_node_pool["2"]
}
