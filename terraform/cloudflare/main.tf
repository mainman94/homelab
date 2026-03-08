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

moved {
  from = cloudflare_dns_record.a_records_hauptmann_dev["*.hauptmann.dev"]
  to   = module.hauptmann_dev_cloudflare.cloudflare_dns_record.a_records["*.hauptmann.dev"]
}

moved {
  from = cloudflare_dns_record.a_records_hauptmann_dev["hauptmann.dev"]
  to   = module.hauptmann_dev_cloudflare.cloudflare_dns_record.a_records["hauptmann.dev"]
}

moved {
  from = cloudflare_dns_record.cname_backend_records_hauptmann_dev["registry"]
  to   = module.hauptmann_dev_cloudflare.cloudflare_dns_record.cname_tunnel_records["registry"]
}

moved {
  from = cloudflare_dns_record.txt_spf
  to   = module.hauptmann_dev_cloudflare.cloudflare_dns_record.txt_spf[0]
}

moved {
  from = cloudflare_dns_record.txt_dkim
  to   = module.hauptmann_dev_cloudflare.cloudflare_dns_record.txt_dkim[0]
}

moved {
  from = cloudflare_email_routing_rule.forward_hello
  to   = module.hauptmann_dev_cloudflare.cloudflare_email_routing_rule.forwarding_rules["hello"]
}
