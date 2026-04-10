output "talosconfig" {
  description = "Talos client configuration for talosctl."
  value       = data.talos_client_configuration.this.talos_config
  sensitive   = true
}

output "kubeconfig" {
  description = "Kubeconfig retrieved from the Talos control plane."
  value       = talos_cluster_kubeconfig.this.kubeconfig_raw
  sensitive   = true
}

output "controlplane_endpoints" {
  description = "Talos endpoints for the control plane nodes."
  value       = local.talos_endpoints
}

output "machine_configurations" {
  description = "Generated Talos machine configurations per node."
  value = {
    for name, config in data.talos_machine_configuration.this :
    name => config.machine_configuration
  }
  sensitive = true
}
