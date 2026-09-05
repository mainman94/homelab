output "installer_image" {
  description = "Talos factory installer image derived from the schematic ID."
  value       = local.install_image
}

output "schematic_id" {
  description = "Factory schematic ID generated from schematic.yaml."
  value       = talos_image_factory_schematic.this.id
}

output "talos_endpoints" {
  description = "Talos API endpoints used by the provider."
  value       = local.endpoints
}

output "talosconfig" {
  description = "Generated talosconfig for the cluster."
  value       = data.talos_client_configuration.this.talos_config
  sensitive   = true
}

output "kubeconfig" {
  description = "Admin kubeconfig downloaded after bootstrap."
  value       = talos_cluster_kubeconfig.this.kubeconfig_raw
  sensitive   = true
}
