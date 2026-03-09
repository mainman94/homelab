moved {
  from = module.homelab_repository
  to   = module.homelab
}

moved {
  from = module.homelab
  to   = module.repositories["homelab"]
}

moved {
  from = module.homelab_terraform_modules_repository
  to   = module.homelab_terraform_modules
}

moved {
  from = module.homelab_terraform_modules
  to   = module.repositories["homelab_terraform_modules"]
}

moved {
  from = module.multi_k8s_infra_repository
  to   = module.multi_k8s_infra
}

moved {
  from = module.multi_k8s_infra
  to   = module.repositories["multi_k8s_infra"]
}

module "repositories" {
  for_each = var.repositories
  source   = "git::https://github.com/mainman94/homelab-terraform-modules.git//modules/github?ref=github-0.1.2"

  name         = each.value.name
  description  = try(each.value.description, null)
  homepage_url = try(each.value.homepage_url, null)
  visibility   = each.value.visibility
  topics       = each.value.topics
  has_issues   = each.value.has_issues
  has_projects = each.value.has_projects
  has_wiki     = each.value.has_wiki

  allow_merge_commit     = try(each.value.allow_merge_commit, null)
  allow_squash_merge     = try(each.value.allow_squash_merge, null)
  allow_rebase_merge     = try(each.value.allow_rebase_merge, null)
  allow_auto_merge       = try(each.value.allow_auto_merge, null)
  delete_branch_on_merge = try(each.value.delete_branch_on_merge, null)
  allow_update_branch    = try(each.value.allow_update_branch, null)
  allow_forking          = each.value.allow_forking

  archived             = each.value.archived
  archive_on_destroy   = each.value.archive_on_destroy
  vulnerability_alerts = try(each.value.vulnerability_alerts, null)
  default_branch       = each.value.default_branch
}
