module "homelab_repository" {
  source = "git::https://github.com/mainman94/homelab-terraform-modules.git//modules/github?ref=github-0.1.2"

  name         = var.repository_name
  description  = var.repository_description
  homepage_url = var.repository_homepage_url
  visibility   = var.repository_visibility
  topics       = var.repository_topics
  has_issues   = var.repository_has_issues
  has_projects = var.repository_has_projects
  has_wiki     = var.repository_has_wiki

  allow_merge_commit     = var.repository_allow_merge_commit
  allow_squash_merge     = var.repository_allow_squash_merge
  allow_rebase_merge     = var.repository_allow_rebase_merge
  allow_auto_merge       = var.repository_allow_auto_merge
  delete_branch_on_merge = var.repository_delete_branch_on_merge
  allow_update_branch    = var.repository_allow_update_branch
  allow_forking          = var.repository_allow_forking

  archived             = var.repository_archived
  archive_on_destroy   = var.repository_archive_on_destroy
  vulnerability_alerts = var.repository_vulnerability_alerts
  default_branch       = var.repository_default_branch
}

module "homelab_terraform_modules_repository" {
  source = "git::https://github.com/mainman94/homelab-terraform-modules.git//modules/github?ref=github-0.1.2"

  name         = var.modules_repository_name
  description  = var.modules_repository_description
  homepage_url = var.modules_repository_homepage_url
  visibility   = var.modules_repository_visibility
  topics       = var.modules_repository_topics
  has_issues   = var.modules_repository_has_issues
  has_projects = var.modules_repository_has_projects
  has_wiki     = var.modules_repository_has_wiki

  allow_merge_commit     = var.modules_repository_allow_merge_commit
  allow_squash_merge     = var.modules_repository_allow_squash_merge
  allow_rebase_merge     = var.modules_repository_allow_rebase_merge
  allow_auto_merge       = var.modules_repository_allow_auto_merge
  delete_branch_on_merge = var.modules_repository_delete_branch_on_merge
  allow_update_branch    = var.modules_repository_allow_update_branch
  allow_forking          = var.modules_repository_allow_forking

  archived             = var.modules_repository_archived
  archive_on_destroy   = var.modules_repository_archive_on_destroy
  vulnerability_alerts = var.modules_repository_vulnerability_alerts
  default_branch       = var.modules_repository_default_branch
}
