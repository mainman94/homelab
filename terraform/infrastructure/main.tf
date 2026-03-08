module "backblaze_b2_backup" {
  source = "git::https://github.com/mainman94/homelab-terraform-modules.git//modules/backblaze?ref=0.1.0"

  bucket_name = var.bucket_name
}

