output "schematic_id" {
  description = "Image Factory schematic ID for the resolved system extensions."
  value       = talos_image_factory_schematic.this.id
}

output "installer_image" {
  description = "Installer image to pass to `talosctl upgrade --image`."
  value       = data.talos_image_factory_urls.this.urls.installer
}

output "iso_url" {
  description = "Factory ISO for this schematic — what to boot a new node from."
  value       = data.talos_image_factory_urls.this.urls.iso
}

output "pxe_url" {
  description = "Factory PXE boot script URL for this schematic."
  value       = data.talos_image_factory_urls.this.urls.pxe
}

output "system_extensions" {
  description = "System extensions baked into the installer, as the factory resolved them."
  value       = local.resolved_extensions
}

output "talos_endpoints" {
  description = "Talos API endpoints for the control plane nodes."
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
