# Publishes the private git-hosted modules (currently consumed via
# git::...?ref=<prefix>-x.y.z source URLs) into the TFC private module
# registry, so consumers can pin with source + version instead of a git ref.
locals {
  registry_modules = {
    "cloudflare" = {
      module_provider  = "cloudflare"
      tag_prefix       = "cloudflare-"
      source_directory = "modules/cloudflare"
    }
    "github" = {
      module_provider  = "github"
      tag_prefix       = "github-"
      source_directory = "modules/github"
    }
    "backblaze" = {
      module_provider  = "b2"
      tag_prefix       = "backblaze-"
      source_directory = "modules/backblaze"
    }
  }
}

resource "tfe_registry_module" "this" {
  for_each = local.registry_modules

  organization    = var.organization
  name            = each.key
  module_provider = each.value.module_provider

  vcs_repo {
    identifier                 = var.module_repo_identifier
    github_app_installation_id = var.github_app_installation_id
    source_directory           = each.value.source_directory
    tags                       = true
    tag_prefix                 = each.value.tag_prefix
  }
}
