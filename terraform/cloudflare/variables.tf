variable "vault_address" {
  description = "OpenBao API address (public, GeoBlock-exempt host so HCP runners reach it)"
  type        = string
  default     = "https://vault.hauptmann.dev"
}

variable "cloudflare_domain" {
  description = "Cloudflare zone / domain name"
  type        = string
  default     = "hauptmann.dev"
}

variable "public_ip" {
  description = "The public IP address for A records."
  type        = string
  default     = "84.115.110.237"
}

variable "a_records_hauptmann_dev" {
  description = "A list of a records"
  type        = set(string)
  default = [
    "*.hauptmann.dev",
    "hauptmann.dev",
  ]
}

variable "cname_backend_records" {
  description = "A list of CNAME records for backend services."
  type        = set(string)
  default     = []
}