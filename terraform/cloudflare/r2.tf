# R2 bucket for CloudNativePG base backups + WAL archive (Barman Cloud plugin
# in multi-k8s-infra). A second provider next to Velero on B2, so losing one
# account does not take both backups. EU jurisdiction: the Keycloak database
# holds personal data. Endpoint:
#   https://<account_id>.eu.r2.cloudflarestorage.com
resource "cloudflare_r2_bucket" "cnpg_backup" {
  account_id   = var.cloudflare_account_id
  name         = "pmhme-cnpg-backup"
  jurisdiction = "eu"
}

data "cloudflare_account_api_token_permission_groups_list" "r2_bucket_item_write" {
  account_id = var.cloudflare_account_id
  name       = "Workers%20R2%20Storage%20Bucket%20Item%20Write"
}

# Object read/write on this one bucket only; cannot list or create buckets.
resource "cloudflare_account_token" "cnpg_backup" {
  account_id = var.cloudflare_account_id
  name       = "cnpg-backup-r2"

  policies = [{
    effect            = "allow"
    permission_groups = [{ id = data.cloudflare_account_api_token_permission_groups_list.r2_bucket_item_write.result[0].id }]
    resources = jsonencode({
      "com.cloudflare.edge.r2.bucket.${var.cloudflare_account_id}_eu_${cloudflare_r2_bucket.cnpg_backup.name}" = "*"
    })
  }]
}

# R2's S3 credentials are derived from the token: access key = token ID,
# secret = SHA-256 of the token value. Both land in TFC state through the
# token resource either way; ESO reads them from here (eso-reader: prod/*).
resource "vault_kv_secret_v2" "cnpg_backup" {
  mount = "homelab"
  name  = "prod/cnpg-backup"
  data_json = jsonencode({
    ACCESS_KEY_ID     = cloudflare_account_token.cnpg_backup.id
    SECRET_ACCESS_KEY = sha256(cloudflare_account_token.cnpg_backup.value)
  })
}
