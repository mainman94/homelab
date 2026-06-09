module "backblaze_b2_backup" {
  source = "git::https://github.com/mainman94/homelab-terraform-modules.git//modules/backblaze?ref=backblaze-0.1.1"

  bucket_name = var.bucket_name
}

module "backblaze_b2_opencloud" {
  source = "git::https://github.com/mainman94/homelab-terraform-modules.git//modules/backblaze?ref=backblaze-0.1.1"

  bucket_name = var.bucket_name_opencloud
}
