output "k8s_cluster_id" {
  value = oci_containerengine_cluster.k8s_cluster.id
}

output "public_subnet_id" {
  value = oci_core_subnet.vcn_public_subnet.id
}

# The stack runs two pools; this keeps the output a single id, as it has
# always been declared. Use k8s_node_pool_2.id explicitly if the second one
# is ever needed.
output "node_pool_id" {
  value = oci_containerengine_node_pool.k8s_node_pool_1.id
}

output "kubernetes_version" {
  value = var.kubernetes_version
}
