variable "vault_address" {
  description = "OpenBao API address (LAN NodePort — reached from the homelab agent pool)"
  type        = string
  default     = "http://192.168.0.129:30020"
}

variable "github_owner" {
  description = "GitHub owner that contains the repository."
  type        = string
  default     = "mainman94"
}

variable "repositories" {
  description = "GitHub repositories managed by this stack, keyed by stable Terraform identifiers."
  type = map(object({
    name                            = string
    description                     = optional(string)
    homepage_url                    = optional(string)
    visibility                      = optional(string, "public")
    topics                          = optional(set(string), [])
    has_issues                      = optional(bool, true)
    has_projects                    = optional(bool, false)
    has_wiki                        = optional(bool, false)
    allow_merge_commit              = optional(bool)
    allow_squash_merge              = optional(bool)
    allow_rebase_merge              = optional(bool)
    allow_auto_merge                = optional(bool)
    delete_branch_on_merge          = optional(bool, true)
    allow_update_branch             = optional(bool)
    allow_forking                   = optional(bool, true)
    archived                        = optional(bool, false)
    archive_on_destroy              = optional(bool, true)
    vulnerability_alerts            = optional(bool, true)
    secret_scanning                 = optional(bool)
    secret_scanning_push_protection = optional(bool)
    dependabot_security_updates     = optional(bool)
    default_branch                  = optional(string, "main")
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
      name        = "homelab"
      description = "Terraform, Ansible and OpenBao configuration for the Eggenberg homelab"
      topics      = ["terraform", "opentofu", "homelab", "openbao", "talos"]

      has_projects = false
      has_wiki     = false

      rulesets = {
        default_branch = {
          name = "default-branch-protection"
          rules = {
            deletion                = true
            non_fast_forward        = true
            required_linear_history = true
            pull_request = {
              # Zero approvals on purpose: GitHub does not let you approve your
              # own pull request, so anything higher locks a solo owner out.
              # The point of the rule is that the TFC plan and Trivy run before
              # a change reaches main, not review.
              required_approving_review_count   = 0
              required_review_thread_resolution = true
              allowed_merge_methods             = ["squash", "rebase"]
            }
            # Only checks that run on *every* pull request belong here: a
            # path-filtered workflow never reports on a PR outside its paths,
            # and a required check that never reports blocks the merge for
            # good. integration_id pins each context to the GitHub Actions app
            # so nothing else can post a passing check under the same name.
            required_status_checks = {
              required_checks = [
                { context = "pre-commit", integration_id = 15368 },
                { context = "validate (cloudflare)", integration_id = 15368 },
                { context = "validate (github)", integration_id = 15368 },
                { context = "validate (infrastructure)", integration_id = 15368 },
                { context = "validate (oci-free-cloud-k8s)", integration_id = 15368 },
                { context = "validate (openbao)", integration_id = 15368 },
                { context = "validate (pocket-id)", integration_id = 15368 },
                { context = "validate (talos)", integration_id = 15368 },
                { context = "tftest (talos)", integration_id = 15368 },
              ]
            }
          }
        }
      }
    }
    homelab_terraform_modules = {
      name        = "homelab-terraform-modules"
      description = "Shared Terraform modules consumed by the homelab stacks"
      topics      = ["terraform", "opentofu", "terraform-modules", "homelab"]

      has_projects = true
      has_wiki     = true

      rulesets = {
        default_branch = {
          name = "default-branch-protection"
          rules = {
            deletion                = true
            non_fast_forward        = true
            required_linear_history = true
            pull_request = {
              # Zero approvals on purpose: GitHub does not let you approve your
              # own pull request, so anything higher locks a solo owner out.
              # The point of the rule is that the TFC plan and Trivy run before
              # a change reaches main, not review.
              required_approving_review_count   = 0
              required_review_thread_resolution = true
              allowed_merge_methods             = ["squash", "rebase"]
            }
            required_status_checks = {
              required_checks = [
                { context = "pre-commit", integration_id = 15368 },
                { context = "tftest (backblaze)", integration_id = 15368 },
                { context = "tftest (cloudflare)", integration_id = 15368 },
                { context = "tftest (github)", integration_id = 15368 },
                { context = "trivy", integration_id = 15368 },
              ]
            }
          }
        }
      }
    }
    multi_k8s_infra = {
      name        = "multi-k8s-infra"
      description = "GitOps configuration for the Talos Kubernetes cluster"
      topics      = ["kubernetes", "gitops", "argocd", "talos", "cilium"]

      has_projects = false
      has_wiki     = false

      allow_auto_merge    = true
      allow_update_branch = true

      # Imported from the ruleset that was created in the UI as "Branch-Rule".
      # Deliberately without required_linear_history, and with every merge
      # method left allowed: Renovate auto-merges here.
      rulesets = {
        default_branch = {
          name = "default-branch-protection"
          rules = {
            deletion         = true
            non_fast_forward = true
            pull_request = {
              required_approving_review_count   = 0
              required_review_thread_resolution = true
            }
            # Renovate auto-merges here, which is exactly why these are
            # required: without them "auto-merge" means "merge whatever, the
            # checks are advisory". ArgoCD applies what reaches main.
            required_status_checks = {
              required_checks = [
                { context = "pre-commit", integration_id = 15368 },
                { context = "Schema Validation (kubeconform)", integration_id = 15368 },
                { context = "Best Practices (kube-linter)", integration_id = 15368 },
                { context = "Security Scan (checkov)", integration_id = 15368 },
              ]
            }
          }
        }
      }
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
    agents = {
      name        = ".agents"
      description = "Private agent configuration"
      visibility  = "private"

      has_projects = false
      has_wiki     = false

      # allow_forking defaults to true, but GitHub rejects that on a
      # user-owned (non-org) private repository: "Allow forks setting can
      # only be changed on org-owned private repositories".
      allow_forking = false

      # The repo was created empty (no auto_init) and has no branches yet, so
      # there is nothing for github_branch_default to point at. Leave it null
      # until a first push exists; GitHub then sets the pushed branch as
      # default on its own.
      default_branch = null
    }
    pp_portfolio_classifier = {
      name        = "pp-portfolio-classifier"
      description = "Portfolio classifier rewrite in Go"
      visibility  = "public"

      has_projects = false
      has_wiki     = false

      rulesets = {
        default_branch = {
          name = "default-branch-protection"
          rules = {
            deletion         = true
            non_fast_forward = true
          }
        }
      }
    }
    dev_config = {
      name        = "dev-config"
      description = "Personal development environment configuration"
      visibility  = "public"

      has_projects = true
      has_wiki     = true

      rulesets = {
        default_branch = {
          name = "default-branch-protection"
          rules = {
            deletion         = true
            non_fast_forward = true
          }
        }
      }
    }
    docker_stack = {
      name        = "docker-stack"
      description = "Docker Compose services running on the homelab hosts"
      topics      = ["docker", "docker-compose", "homelab", "self-hosted"]

      # Every merge method stays allowed: Renovate auto-merges patch updates here.
      rulesets = {
        default_branch = {
          name = "default-branch-protection"
          rules = {
            deletion         = true
            non_fast_forward = true
            pull_request = {
              required_approving_review_count   = 0
              required_review_thread_resolution = true
            }
            # The image CVE sweep (scan.yml) is deliberately absent: it is
            # path-filtered and advisory, and a required check that does not
            # run on every PR blocks the merge for good.
            required_status_checks = {
              required_checks = [
                { context = "pre-commit", integration_id = 15368 },
              ]
            }
          }
        }
      }
    }
    docker_strapi = {
      name        = "docker-strapi"
      description = "Strapi Docker images, fixed and republished"
      visibility  = "public"

      has_projects = false
      has_wiki     = false

      rulesets = {
        default_branch = {
          name = "default-branch-protection"
          # auto-check-new-releases.yml and manual-release.yml push straight to
          # main with the PAT — that push is what triggers a publish, and a
          # required status check would otherwise reject it (the checks have
          # not run for a commit that does not exist yet). Repository admins
          # bypass; every pull request still has to be green.
          bypass_actors = [
            {
              actor_type  = "RepositoryRole"
              actor_id    = 5 # admin
              bypass_mode = "always"
            }
          ]
          rules = {
            deletion         = true
            non_fast_forward = true
            # This repo publishes public images: the lint and smoke-tested
            # build for both variants gate the branch that triggers a publish.
            required_status_checks = {
              required_checks = [
                { context = "lint (alpine)", integration_id = 15368 },
                { context = "lint (debian)", integration_id = 15368 },
                { context = "build (alpine)", integration_id = 15368 },
                { context = "build (debian)", integration_id = 15368 },
              ]
            }
          }
        }
      }
    }
    profile = {
      name = "mainman94"

      has_projects = true
      has_wiki     = true
    }
    # Archived: GitHub rejects writes to archived repositories, so every value
    # here mirrors the repository as it stands and the security toggles below
    # stay untouched.
    beartainer = {
      name     = "beartainer"
      archived = true

      has_projects = true
      has_wiki     = true

      delete_branch_on_merge = false
      vulnerability_alerts   = false
    }
  }
}
