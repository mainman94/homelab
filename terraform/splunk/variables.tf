variable "vault_address" {
  description = "OpenBao API address (LAN NodePort — reached from the homelab agent pool)"
  type        = string
  default     = "http://192.168.0.129:30020"
}

variable "splunk_realm" {
  description = "Splunk Observability Cloud realm (matches splunkObservability.realm in the otel-collector chart values)"
  type        = string
  default     = "eu0"
}

variable "cluster_name" {
  description = "k8s.cluster.name resource attribute reported by the otel collector"
  type        = string
  default     = "eggenberg-talos-cluster-1"
}
