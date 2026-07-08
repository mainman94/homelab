variable "vault_address" {
  description = "OpenBao API address"
  type        = string
  default     = "http://192.168.0.129:30020"
}

variable "kv_mount" {
  description = "kv-v2 secrets engine mount path"
  type        = string
  default     = "homelab"
}
