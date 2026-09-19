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
  source   = "git::https://github.com/mainman94/homelab-terraform-modules.git//modules/github?ref=github-0.1.9"

  name         = each.value.name
  description  = each.value.description
  visibility   = each.value.visibility
  topics       = each.value.topics
  has_issues   = each.value.has_issues
  has_projects = each.value.has_projects
  has_wiki     = each.value.has_wiki

  allow_auto_merge       = each.value.allow_auto_merge
  delete_branch_on_merge = each.value.delete_branch_on_merge
  allow_update_branch    = each.value.allow_update_branch
  allow_forking          = each.value.allow_forking

  archived                        = each.value.archived
  archive_on_destroy              = each.value.archive_on_destroy
  vulnerability_alerts            = each.value.vulnerability_alerts
  secret_scanning                 = each.value.secret_scanning != null ? each.value.secret_scanning : local.security_default[each.key]
  secret_scanning_push_protection = each.value.secret_scanning_push_protection != null ? each.value.secret_scanning_push_protection : local.security_default[each.key]
  dependabot_security_updates     = each.value.dependabot_security_updates != null ? each.value.dependabot_security_updates : local.security_default[each.key]
  default_branch                  = each.value.default_branch
  rulesets                        = each.value.rulesets
}
