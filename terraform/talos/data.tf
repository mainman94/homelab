# resource "talos_cluster_kubeconfig" "cluster_kubeconfig" {
#   depends_on = [
#     talos_machine_bootstrap.this
#   ]
#   client_configuration = talos_machine_secrets.this.client_configuration
#   node                 = var.cluster_vip
# }