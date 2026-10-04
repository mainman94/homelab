variable "vault_address" {
  description = "OpenBao API address (LAN NodePort — reached from the homelab agent pool)"
  type        = string
  default     = "http://192.168.0.129:30020"
}

variable "keycloak_url" {
  description = "Keycloak base URL (public hostname behind the Cilium Gateway)"
  type        = string
  default     = "https://auth.hauptmann.dev"
}

variable "realm_name" {
  description = "Realm for the homelab applications"
  type        = string
  default     = "homelab"
}
