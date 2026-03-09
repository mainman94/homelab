variable "GH_TOKEN" {
  description = "GitHub token with repository administration permissions."
  type        = string
  sensitive   = true
}

variable "github_owner" {
  description = "GitHub owner that contains the repository."
  type        = string
  default     = "mainman94"
}

variable "repositories" {
  description = "GitHub repositories managed by this stack, keyed by stable Terraform identifiers."
  type = map(object({
    name                   = string
    description            = optional(string)
    homepage_url           = optional(string)
    visibility             = optional(string, "public")
    topics                 = optional(set(string), [])
    has_issues             = optional(bool, true)
    has_projects           = optional(bool, false)
    has_wiki               = optional(bool, false)
    allow_merge_commit     = optional(bool)
    allow_squash_merge     = optional(bool)
    allow_rebase_merge     = optional(bool)
    allow_auto_merge       = optional(bool)
    delete_branch_on_merge = optional(bool)
    allow_update_branch    = optional(bool)
    allow_forking          = optional(bool, true)
    archived               = optional(bool, false)
    archive_on_destroy     = optional(bool, true)
    vulnerability_alerts   = optional(bool)
    default_branch         = optional(string, "main")
  }))
  default = {
    homelab = {
      name = "homelab"

      has_projects = false
      has_wiki     = false
    }
    homelab_terraform_modules = {
      name = "homelab-terraform-modules"

      has_projects = true
      has_wiki     = true
    }
    multi_k8s_infra = {
      name = "multi-k8s-infra"

      has_projects = true
      has_wiki     = true
    }
    portfolio = {
      name        = "portfolio"
      description = "Personal Portfolio Page"
      visibility  = "private"

      has_projects = true
      has_wiki     = false
    }
    portfolio_performance = {
      name        = "portfolio-performance"
      description = "Private portfolio performance files"
      visibility  = "private"

      has_projects = true
    }
    dev_config = {
      name       = "dev-config"
      visibility = "public"

      has_projects = true
      has_wiki     = true
    }
  }
}
