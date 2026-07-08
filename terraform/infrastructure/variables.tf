variable "vault_address" {
  description = "OpenBao API address (LAN NodePort — reached from the homelab agent pool)"
  type        = string
  default     = "http://192.168.0.129:30020"
}

variable "bucket_name" {
  description = "The name of the bucket to create in Backblaze B2"
  type        = string
  default     = "pmhme-backup"
}

variable "bucket_name_opencloud" {
  description = "The name of the opencloud bucket to create in Backblaze B2"
  type        = string
  default     = "pmhme-opencloud"
}

variable "bucket_name_k8s_backup" {
  description = "The name of the Kubernetes backup bucket to create in Backblaze B2"
  type        = string
  default     = "pmhme-k8s-backup"
}
