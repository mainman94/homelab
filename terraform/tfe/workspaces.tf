locals {
  # All workspaces in the eggenberg-homelab organization.
  # Key is the exact Terraform Cloud workspace name.
  workspaces = {
    "cloudflare" = {
      description       = "Cloudflare DNS, WAF, Zero Trust, and Email Routing"
      working_directory = "terraform/cloudflare"
      execution_mode    = "agent"
      terraform_version = var.terraform_version
      auto_apply        = true
      vcs_connected     = true
      trigger_patterns  = ["terraform/cloudflare/**/*"]
      vault_run_role    = "tfc-cloudflare"
    }
    "github" = {
      description       = "GitHub organization repositories and rulesets governance"
      working_directory = "terraform/github"
      execution_mode    = "agent"
      terraform_version = var.terraform_version
      auto_apply        = true
      vcs_connected     = true
      trigger_patterns  = ["terraform/github/**/*"]
      vault_run_role    = "tfc-github"
    }
    "backblaze" = {
      description       = "Backblaze B2 storage buckets and credentials"
      working_directory = "terraform/infrastructure"
      execution_mode    = "agent"
      terraform_version = var.terraform_version
      auto_apply        = true
      vcs_connected     = true
      trigger_patterns  = ["terraform/infrastructure/**/*"]
      vault_run_role    = "tfc-backblaze"
    }
    "openbao" = {
      description       = "OpenBao secrets engine, ESO Kubernetes auth, and TFC workload-identity auth"
      working_directory = "terraform/openbao"
      execution_mode    = "agent"
      terraform_version = var.terraform_version
      auto_apply        = true
      vcs_connected     = true
      trigger_patterns  = ["terraform/openbao/**/*"]
      vault_run_role    = null
    }
    "pocket-id" = {
      description       = "Pocket ID OIDC users, groups, and clients"
      working_directory = "terraform/pocket-id"
      execution_mode    = "agent"
      terraform_version = var.terraform_version
      auto_apply        = true
      vcs_connected     = true
      trigger_patterns  = ["terraform/pocket-id/**/*"]
      vault_run_role    = "tfc-pocket-id"
    }
    "eggenberg-talos-cluster" = {
      description       = "Talos bare-metal control plane cluster bootstrap and config"
      working_directory = "terraform/talos"
      execution_mode    = "agent"
      terraform_version = var.terraform_version
      auto_apply        = true
      vcs_connected     = true
      trigger_patterns  = ["terraform/talos/**/*"]
      vault_run_role    = null
    }
    "tfe" = {
      description       = "Terraform Cloud workspaces, agent pools, and workload-identity variables"
      working_directory = "terraform/tfe"
      execution_mode    = "agent"
      terraform_version = var.terraform_version
      auto_apply        = true
      vcs_connected     = true
      trigger_patterns  = ["terraform/tfe/**/*"]
      vault_run_role    = null
    }
  }
}

resource "tfe_workspace" "this" {
  for_each = local.workspaces

  name         = each.key
  organization = var.organization
  description  = each.value.description

  working_directory      = each.value.working_directory
  terraform_version      = each.value.terraform_version
  auto_apply             = each.value.auto_apply
  auto_apply_run_trigger = each.value.auto_apply
  queue_all_runs         = false
  trigger_patterns       = each.value.trigger_patterns

  dynamic "vcs_repo" {
    for_each = each.value.vcs_connected ? [1] : []
    content {
      identifier                 = var.vcs_repo_identifier
      github_app_installation_id = var.github_app_installation_id
      ingress_submodules         = false
    }
  }
}

# execution_mode/agent_pool_id live here instead of on tfe_workspace directly;
# that inline attribute is deprecated by the provider in favor of this resource.
resource "tfe_workspace_settings" "this" {
  for_each = local.workspaces

  workspace_id   = tfe_workspace.this[each.key].id
  execution_mode = each.value.execution_mode
  agent_pool_id  = each.value.execution_mode == "agent" ? var.agent_pool_id : null
}
