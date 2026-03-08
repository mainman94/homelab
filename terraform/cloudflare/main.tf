module "hauptmann_dev_cloudflare" {
  source = "git::https://github.com/mainman94/homelab-terraform-modules.git//modules/cloudflare?ref=cloudflare-0.1.0"

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
