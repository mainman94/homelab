variable "vault_address" {
  description = "OpenBao API address (LAN NodePort — reached from the homelab agent pool)"
  type        = string
  default     = "http://192.168.0.129:30020"
}

variable "pocket_id_base_url" {
  description = "Pocket ID instance URL"
  type        = string
  default     = "http://192.168.0.129:30411"
}
