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
    rulesets = optional(map(object({
      name             = string
      target           = optional(string, "branch")
      enforcement      = optional(string, "active")
      ref_name_include = optional(set(string), ["~DEFAULT_BRANCH"])
      ref_name_exclude = optional(set(string), [])
      bypass_actors = optional(list(object({
        actor_id    = optional(number)
        actor_type  = string
        bypass_mode = optional(string, "always")
      })), [])
      rules = object({
        creation                = optional(bool)
        update                  = optional(bool)
        deletion                = optional(bool)
        non_fast_forward        = optional(bool)
        required_linear_history = optional(bool)
        required_signatures     = optional(bool)
        pull_request = optional(object({
          allowed_merge_methods             = optional(set(string), ["merge", "squash", "rebase"])
          dismiss_stale_reviews_on_push     = optional(bool, false)
          require_code_owner_review         = optional(bool, false)
          require_last_push_approval        = optional(bool, false)
          required_approving_review_count   = optional(number, 0)
          required_review_thread_resolution = optional(bool, false)
        }))
        required_status_checks = optional(object({
          strict_required_status_checks_policy = optional(bool, false)
          do_not_enforce_on_create             = optional(bool, false)
          required_checks = set(object({
            context        = string
            integration_id = optional(number)
          }))
        }))
      })
    })), {})
  }))

  validation {
    condition = alltrue([
      for key in keys(var.repositories) : can(regex("^[a-z0-9_]+$", key))
    ])
    error_message = "Repository map keys must use stable Terraform identifiers containing only lowercase letters, digits, and underscores."
  }

  validation {
    condition = length(distinct([
      for repository in values(var.repositories) : repository.name
    ])) == length(var.repositories)
    error_message = "Repository names in the repositories map must be unique."
  }

  validation {
    condition = alltrue([
      for repository in values(var.repositories) : contains(["public", "private", "internal"], repository.visibility)
    ])
    error_message = "Each repository visibility must be one of: public, private, internal."
  }

  validation {
    condition = alltrue([
      for repository in values(var.repositories) : trimspace(repository.default_branch) != ""
    ])
    error_message = "Each repository default_branch must be a non-empty string."
  }

  validation {
    condition = alltrue(flatten([
      for repository in values(var.repositories) : [
        for ruleset in values(try(repository.rulesets, {})) : contains(["branch"], ruleset.target)
      ]
    ]))
    error_message = "Repository rulesets currently support only the branch target in this root stack."
  }

  validation {
    condition = alltrue(flatten([
      for repository in values(var.repositories) : [
        for ruleset in values(try(repository.rulesets, {})) : contains(["active", "disabled", "evaluate"], ruleset.enforcement)
      ]
    ]))
    error_message = "Repository ruleset enforcement must be one of: active, disabled, evaluate."
  }

  validation {
    condition = alltrue(flatten([
      for repository in values(var.repositories) : [
        for ruleset in values(try(repository.rulesets, {})) : ruleset.rules.pull_request == null ? true : (
          ruleset.rules.pull_request.required_approving_review_count >= 0 &&
          ruleset.rules.pull_request.required_approving_review_count <= 6
        )
      ]
    ]))
    error_message = "Repository ruleset approval counts must be between 0 and 6."
  }

  validation {
    condition = alltrue(flatten([
      for repository in values(var.repositories) : [
        for ruleset in values(try(repository.rulesets, {})) : ruleset.rules.pull_request == null ? true : (
          length(setsubtract(ruleset.rules.pull_request.allowed_merge_methods, toset(["merge", "squash", "rebase"]))) == 0
        )
      ]
    ]))
    error_message = "Repository ruleset allowed_merge_methods may only contain merge, squash, or rebase."
  }

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
