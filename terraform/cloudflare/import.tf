# Temporary import block — delete after `terraform apply` confirms no diff.
import {
  to = cloudflare_ruleset.firewall_custom
  id = "zones/${var.CLOUDFLARE_ZONE_ID_HAUPTMANN_DEV}/b161497560064f779d96876af4769b90"
}
