variable "vault_address" {
  description = "OpenBao API address (public, GeoBlock-exempt host so HCP runners reach it)"
  type        = string
  default     = "https://vault.hauptmann.dev"
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
