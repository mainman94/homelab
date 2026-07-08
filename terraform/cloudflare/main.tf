locals {
  # Secrets from OpenBao (homelab/prod/cloudflare). Required keys: API_KEY,
  # ZONE_ID_HAUPTMANN_DEV, TUNNEL_STRASSGANG_ID, DKIM_HAUPTMANN_DEV, MY_EMAIL.
  cf = data.vault_kv_secret_v2.cloudflare.data
}

module "hauptmann_dev_cloudflare" {
  source = "git::https://github.com/mainman94/homelab-terraform-modules.git//modules/cloudflare?ref=cloudflare-0.1.1"

  zone_id   = local.cf["ZONE_ID_HAUPTMANN_DEV"]
  domain    = var.cloudflare_domain
  public_ip = var.public_ip

  a_records = var.a_records_hauptmann_dev

  tunnel_id            = local.cf["TUNNEL_STRASSGANG_ID"]
  cname_tunnel_records = var.cname_backend_records

  create_spf_record = true
  dkim_record_name  = "cf2024-1._domainkey.hauptmann.dev"
  dkim_public_key   = local.cf["DKIM_HAUPTMANN_DEV"]

  email_routing_rules = [
    {
      name         = "hello"
      local_part   = "hello"
      destinations = [local.cf["MY_EMAIL"]]
    }
  ]
}

resource "cloudflare_ruleset" "firewall_custom" {
  zone_id     = local.cf["ZONE_ID_HAUPTMANN_DEV"]
  name        = "default"
  kind        = "zone"
  phase       = "http_request_firewall_custom"
  description = ""

  rules = [
    {
      ref         = "a0335174c273445ebdfd3f6997bfc8ef"
      description = "GeoBlock"
      action      = "block"
      enabled     = true
      # vault.hauptmann.dev is exempt: TFC runs from outside AT and reads
      # OpenBao over this host. OpenBao's own token/JWT auth is the real gate.
      expression = "(not ip.src.country in {\"AT\"} and http.host strict wildcard r\"*.hauptmann.dev\" and http.host ne \"vault.hauptmann.dev\")"
    }
  ]
}
