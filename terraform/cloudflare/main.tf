module "hauptmann_dev_cloudflare" {
  source = "git::https://github.com/mainman94/homelab-terraform-modules.git//modules/cloudflare?ref=cloudflare-0.1.1"

  zone_id   = var.cloudflare_zone_id
  domain    = var.cloudflare_domain
  public_ip = data.vault_kv_secret_v2.network.data["PUBLIC_IP"]

  a_records = var.a_records_hauptmann_dev

  tunnel_id            = var.tunnel_strassgang_id
  cname_tunnel_records = var.cname_backend_records

  create_spf_record = true
  dkim_record_name  = "cf2024-1._domainkey.hauptmann.dev"
  dkim_public_key   = var.cloudflare_dkim_key

  email_routing_rules = [
    {
      name         = "hello"
      local_part   = "hello"
      destinations = [var.contact_email]
    }
  ]
}

resource "cloudflare_zone_setting" "ssl" {
  zone_id    = var.cloudflare_zone_id
  setting_id = "ssl"
  value      = "full"
}

resource "cloudflare_zone_setting" "always_use_https" {
  zone_id    = var.cloudflare_zone_id
  setting_id = "always_use_https"
  value      = "on"
}

resource "cloudflare_zone_setting" "min_tls_version" {
  zone_id    = var.cloudflare_zone_id
  setting_id = "min_tls_version"
  value      = "1.2"
}

resource "cloudflare_zone_setting" "security_level" {
  zone_id    = var.cloudflare_zone_id
  setting_id = "security_level"
  value      = "medium"
}

resource "cloudflare_zone_setting" "browser_check" {
  zone_id    = var.cloudflare_zone_id
  setting_id = "browser_check"
  value      = "on"
}

resource "cloudflare_zone_setting" "security_header" {
  zone_id    = var.cloudflare_zone_id
  setting_id = "security_header"
  value = {
    strict_transport_security = {
      enabled            = true
      max_age            = 15552000
      include_subdomains = true
      preload            = true
      nosniff            = true
    }
  }
}

resource "cloudflare_bot_management" "default" {
  zone_id                 = var.cloudflare_zone_id
  fight_mode              = true
  enable_js               = true
  ai_bots_protection      = "block"
  content_bots_protection = "disabled"
  crawler_protection      = "enabled"
  is_robots_txt_managed   = true
}

resource "cloudflare_zone_dnssec" "default" {
  zone_id             = var.cloudflare_zone_id
  status              = "active"
  dnssec_multi_signer = true
}

resource "cloudflare_ruleset" "firewall_custom" {
  zone_id     = var.cloudflare_zone_id
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
