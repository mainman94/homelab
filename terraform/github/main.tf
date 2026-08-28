# Security toggles default to on for public repositories. Private ones stay
# untouched — secret scanning there needs GitHub Advanced Security — and so do
# archived ones, which GitHub serves read-only.
locals {
  security_default = {
    for key, repository in var.repositories :
    key => repository.archived || repository.visibility != "public" ? null : true
  }
}

module "repositories" {
  for_each = var.repositories
  source   = "git::https://github.com/mainman94/homelab-terraform-modules.git//modules/github?ref=github-0.1.8"

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

  archived                        = each.value.archived
  archive_on_destroy              = each.value.archive_on_destroy
  vulnerability_alerts            = try(each.value.vulnerability_alerts, null)
  secret_scanning                 = each.value.secret_scanning != null ? each.value.secret_scanning : local.security_default[each.key]
  secret_scanning_push_protection = each.value.secret_scanning_push_protection != null ? each.value.secret_scanning_push_protection : local.security_default[each.key]
  dependabot_security_updates     = each.value.dependabot_security_updates != null ? each.value.dependabot_security_updates : local.security_default[each.key]
  default_branch                  = each.value.default_branch
  rulesets                        = try(each.value.rulesets, {})
}
