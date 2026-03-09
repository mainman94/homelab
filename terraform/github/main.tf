module "repositories" {
  for_each = var.repositories
  source   = "git::https://github.com/mainman94/homelab-terraform-modules.git//modules/github?ref=github-0.1.4"

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
  rulesets             = try(each.value.rulesets, {})
}
