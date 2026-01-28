################################
#  CNAME records for frontend  #
################################
resource "cloudflare_dns_record" "cname_frontend_records_hauptmann_dev" {
  for_each = var.a_records_hauptmann_dev
  zone_id  = var.CLOUDFLARE_ZONE_ID_HAUPTMANN_DEV
  name     = each.key
  content  = "${var.CLOUDFLARE_TUNNEL_EGGENBERG_ID}.cfargotunnel.com"
  type     = "CNAME"
  ttl      = 1
  proxied  = true
}

################################
#  CNAME records for backend   #
################################
resource "cloudflare_dns_record" "cname_backend_records_hauptmann_dev" {
  for_each = var.cname_backend_records
  zone_id  = var.CLOUDFLARE_ZONE_ID_HAUPTMANN_DEV
  name     = each.key
  content  = "${var.CLOUDFLARE_TUNNEL_STRASSGANG_ID}.cfargotunnel.com"
  type     = "CNAME"
  ttl      = 1
  proxied  = true
}