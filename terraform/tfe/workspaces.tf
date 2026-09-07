locals {
  # All workspaces in the eggenberg-homelab organization.
  # Key is the exact Terraform Cloud workspace name.
  workspaces = {
    "cloudflare" = {
      description       = "Cloudflare DNS, WAF, Zero Trust, and Email Routing"
      working_directory = "terraform/cloudflare"
      execution_mode    = "agent"
      terraform_version = "~> 1.10.0"
      auto_apply        = false
      vault_run_role    = "tfc-cloudflare"
    }
    "github" = {
      description       = "GitHub organization repositories and rulesets governance"
      working_directory = "terraform/github"
      execution_mode    = "agent"
      terraform_version = "~> 1.10.0"
      auto_apply        = false
      vault_run_role    = "tfc-github"
    }
    "backblaze" = {
      description       = "Backblaze B2 storage buckets and credentials"
      working_directory = "terraform/infrastructure"
      execution_mode    = "agent"
      terraform_version = "~> 1.10.0"
      auto_apply        = false
      vault_run_role    = "tfc-backblaze"
    }
    "openbao" = {
      description       = "OpenBao secrets engine, ESO Kubernetes auth, and TFC workload-identity auth"
      working_directory = "terraform/openbao"
      execution_mode    = "agent"
      terraform_version = "~> 1.6.0"
      auto_apply        = false
      vault_run_role    = null
    }
    "pocket-id" = {
      description       = "Pocket ID OIDC users, groups, and clients"
      working_directory = "terraform/pocket-id"
      execution_mode    = "agent"
      terraform_version = "~> 1.10.0"
      auto_apply        = false
      vault_run_role    = "tfc-pocket-id"
    }
    "eggenberg-talos-cluster" = {
      description       = "Talos bare-metal control plane cluster bootstrap and config"
      working_directory = "terraform/talos"
      execution_mode    = "local"
      terraform_version = "~> 1.6.0"
      auto_apply        = false
      vault_run_role    = null
    }
    "tfe" = {
      description       = "Terraform Cloud workspaces, agent pools, and workload-identity variables"
      working_directory = "terraform/tfe"
      execution_mode    = "remote"
      terraform_version = "~> 1.10.0"
      auto_apply        = false
      vault_run_role    = null
    }
  }
}

resource "tfe_workspace" "this" {
  for_each = local.workspaces

  name         = each.key
  organization = var.organization
  description  = each.value.description

  working_directory = each.value.working_directory
  execution_mode    = each.value.execution_mode
  terraform_version = each.value.terraform_version
  auto_apply        = each.value.auto_apply

  agent_pool_id = each.value.execution_mode == "agent" ? var.agent_pool_id : null

  dynamic "vcs_repo" {
    for_each = var.oauth_token_id != null ? [1] : []
    content {
      identifier     = var.vcs_repo_identifier
      oauth_token_id = var.oauth_token_id
    }
  }
}
