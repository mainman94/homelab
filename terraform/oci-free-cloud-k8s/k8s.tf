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
  depends_on      = [oci_containerengine_node_pool.k8s_node_pool]
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

data "oci_containerengine_node_pool_option" "node_pool_options" {
  node_pool_option_id = "all"
  compartment_id      = var.compartment_id
}

# Node Pool 1 (AD-verteilt, 1 Node)
resource "oci_containerengine_node_pool" "k8s_node_pool_1" {
  cluster_id         = oci_containerengine_cluster.k8s_cluster.id
  compartment_id     = var.compartment_id
  kubernetes_version = var.kubernetes_version
  name               = "k8s-node-pool-1"

  node_config_details {
    # Nur eine Placement Config pro Pool (oder loop über 1–2 ADs, aber einfach halten)
    placement_configs {
      availability_domain = data.oci_identity_availability_domains.ads.availability_domains[0].name  # z. B. AD-1
      subnet_id           = oci_core_subnet.vcn_private_subnet.id
    }

    size = 1  # Kritisch: Nur 1 Node!
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

# Node Pool 2 (andere AD, 1 Node) – für HA
resource "oci_containerengine_node_pool" "k8s_node_pool_2" {
  # Fast identisch zu Pool 1
  cluster_id         = oci_containerengine_cluster.k8s_cluster.id
  compartment_id     = var.compartment_id
  kubernetes_version = var.kubernetes_version
  name               = "k8s-node-pool-2"

  node_config_details {
    placement_configs {
      availability_domain = data.oci_identity_availability_domains.ads.availability_domains[1].name  # z. B. AD-2
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