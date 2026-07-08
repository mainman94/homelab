variable "vault_address" {
  description = "OpenBao API address (LAN NodePort — reached from the homelab agent pool)"
  type        = string
  default     = "http://192.168.0.129:30020"
}

variable "cloudflare_domain" {
  description = "Cloudflare zone / domain name"
  type        = string
  default     = "hauptmann.dev"
}

variable "cloudflare_zone_id" {
  description = "Cloudflare zone ID for hauptmann.dev (not secret — public identifier)"
  type        = string
  default     = "3991ce1005b14f7de31157b1b5b7b2ef"
}

variable "cloudflare_dkim_key" {
  description = "DKIM public key TXT value for cf2024-1._domainkey.hauptmann.dev (public)"
  type        = string
  default     = "v=DKIM1; h=sha256; k=rsa; p=MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAiweykoi+o48IOGuP7GR3X0MOExCUDY/BCRHoWBnh3rChl7WhdyCxW3jgq1daEjPPqoi7sJvdg5hEQVsgVRQP4DcnQDVjGMbASQtrY4WmB1VebF+RPJB2ECPsEDTpeiI5ZyUAwJaVX7r6bznU67g7LvFq35yIo4sdlmtZGV+i0H4cpYH9+3JJ78km4KXwaf9xUJCWF6nxeD+qG6Fyruw1Qlbds2r85U9dkNDVAS3gioCvELryh1TxKGiVTkg4wqHTyHfWsp7KD3WQHYJn0RyfJJu6YEmL77zonn7p2SRMvTMP3ZEXibnC9gz3nnhR6wcYL8Q7zXypKTMD58bTixDSJwIDAQAB"
}

# Sensitive — set as terraform workspace vars on `cloudflare` (not in this
# public repo). No defaults on purpose.
variable "tunnel_strassgang_id" {
  description = "Cloudflare Tunnel ID for Strassgang"
  type        = string
  sensitive   = true
}

variable "contact_email" {
  description = "Destination address for the hello@ email routing rule"
  type        = string
  sensitive   = true
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