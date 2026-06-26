module "hauptmann_dev_cloudflare" {
  source = "git::https://github.com/mainman94/homelab-terraform-modules.git//modules/cloudflare?ref=cloudflare-0.1.1"

  zone_id   = var.CLOUDFLARE_ZONE_ID_HAUPTMANN_DEV
  domain    = var.cloudflare_domain
  public_ip = var.public_ip

  a_records = var.a_records_hauptmann_dev

  tunnel_id            = var.CLOUDFLARE_TUNNEL_STRASSGANG_ID
  cname_tunnel_records = var.cname_backend_records

  create_spf_record = true
  dkim_record_name  = "cf2024-1._domainkey.hauptmann.dev"
  dkim_public_key   = var.cloudflare_dkim_key

  email_routing_rules = [
    {
      name         = "hello"
      local_part   = "hello"
      destinations = [var.MY_EMAIL]
    }
  ]
}

resource "cloudflare_ruleset" "firewall_custom" {
  zone_id     = var.CLOUDFLARE_ZONE_ID_HAUPTMANN_DEV
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
      expression  = "(not ip.src.country in {\"AT\"} and http.host strict wildcard r\"*.hauptmann.dev\")"
    }
  ]
}
