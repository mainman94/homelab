# One-shot: import existing UI-configured zone settings into state.
# Remove this file after a successful `terraform apply`.

import {
  to = cloudflare_zone_setting.ssl
  id = "${var.cloudflare_zone_id}/ssl"
}

import {
  to = cloudflare_zone_setting.always_use_https
  id = "${var.cloudflare_zone_id}/always_use_https"
}

import {
  to = cloudflare_zone_setting.min_tls_version
  id = "${var.cloudflare_zone_id}/min_tls_version"
}

import {
  to = cloudflare_zone_setting.security_level
  id = "${var.cloudflare_zone_id}/security_level"
}

import {
  to = cloudflare_zone_setting.browser_check
  id = "${var.cloudflare_zone_id}/browser_check"
}

import {
  to = cloudflare_zone_setting.security_header
  id = "${var.cloudflare_zone_id}/security_header"
}

import {
  to = cloudflare_bot_management.default
  id = var.cloudflare_zone_id
}

import {
  to = cloudflare_zone_dnssec.default
  id = var.cloudflare_zone_id
}
