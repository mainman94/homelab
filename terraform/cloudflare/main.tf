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

locals {
  vault_api_skip_ip_condition = length(var.vault_api_allow_cidrs) > 0 ? " and ip.src in {${join(" ", sort(tolist(var.vault_api_allow_cidrs)))}}" : ""
  vault_api_skip_expression   = "(http.host eq \"${var.vault_api_hostname}\" and starts_with(http.request.uri.path, \"/v1/\"))${local.vault_api_skip_ip_condition}"
}

resource "cloudflare_ruleset" "vault_api_skip" {
  zone_id = var.CLOUDFLARE_ZONE_ID_HAUPTMANN_DEV
  name    = "Vault API Client Allowlist"
  kind    = "zone"
  phase   = "http_request_firewall_custom"

  rules = [
    {
      ref         = "vault_api_skip_security"
      description = "Skip challenge/security checks for trusted Vault API clients."
      enabled     = var.vault_api_skip_rule_enabled
      expression  = local.vault_api_skip_expression
      action      = "skip"
      action_parameters = {
        phases = [
          "http_request_firewall_managed",
          "http_request_sbfm",
          "http_ratelimit",
        ]
        products = [
          "bic",
          "rateLimit",
          "securityLevel",
          "waf",
        ]
      }
    }
  ]
}
