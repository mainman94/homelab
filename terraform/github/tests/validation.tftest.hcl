# Variable validation for the GitHub governance stack.
#
# This is the stack that decides who can push what to every repository in the
# account, so the object model's guard rails are worth pinning down: a typo in
# a ruleset that silently produces *no* rule is worse than a plan that fails.
#
# Every run here is a rejection test. Terraform evaluates variable validations
# before it configures providers, so these need no credentials and never reach
# GitHub or Vault — which is also why there is no happy-path plan: this stack's
# github provider is configured from an ephemeral Vault read, and a plan cannot
# get past that without a real OpenBao. `terraform validate` covers the shape;
# CI's TFC plan covers the rest.

mock_provider "github" {}
mock_provider "vault" {}

run "rejects_a_non_identifier_map_key" {
  command = plan

  variables {
    repositories = {
      "Not-An-Identifier" = {
        name = "some-repo"
      }
    }
  }

  expect_failures = [var.repositories]
}

# Two entries pointing at the same repository would have the two module
# instances fight over its settings on every apply.
run "rejects_duplicate_repository_names" {
  command = plan

  variables {
    repositories = {
      first = {
        name = "duplicated"
      }
      second = {
        name = "duplicated"
      }
    }
  }

  expect_failures = [var.repositories]
}

run "rejects_an_unknown_visibility" {
  command = plan

  variables {
    repositories = {
      example = {
        name       = "example"
        visibility = "secret"
      }
    }
  }

  expect_failures = [var.repositories]
}

run "rejects_an_empty_default_branch" {
  command = plan

  variables {
    repositories = {
      example = {
        name           = "example"
        default_branch = "  "
      }
    }
  }

  expect_failures = [var.repositories]
}

# Only branch rulesets are wired up in this stack; a tag ruleset would be
# accepted by the type and then produce nothing.
run "rejects_a_non_branch_ruleset_target" {
  command = plan

  variables {
    repositories = {
      example = {
        name = "example"
        rulesets = {
          default_branch = {
            name   = "default-branch-protection"
            target = "tag"
            rules = {
              deletion = true
            }
          }
        }
      }
    }
  }

  expect_failures = [var.repositories]
}

run "rejects_an_unknown_ruleset_enforcement" {
  command = plan

  variables {
    repositories = {
      example = {
        name = "example"
        rulesets = {
          default_branch = {
            name        = "default-branch-protection"
            enforcement = "maybe"
            rules = {
              deletion = true
            }
          }
        }
      }
    }
  }

  expect_failures = [var.repositories]
}

# GitHub caps required approvals at 6; anything higher is a ruleset the API
# rejects at apply time.
run "rejects_too_many_required_approvals" {
  command = plan

  variables {
    repositories = {
      example = {
        name = "example"
        rulesets = {
          default_branch = {
            name = "default-branch-protection"
            rules = {
              pull_request = {
                required_approving_review_count = 7
              }
            }
          }
        }
      }
    }
  }

  expect_failures = [var.repositories]
}

run "rejects_an_unknown_merge_method" {
  command = plan

  variables {
    repositories = {
      example = {
        name = "example"
        rulesets = {
          default_branch = {
            name = "default-branch-protection"
            rules = {
              pull_request = {
                allowed_merge_methods = ["squash", "fast-forward"]
              }
            }
          }
        }
      }
    }
  }

  expect_failures = [var.repositories]
}
