# Adoption of repositories and rulesets that already exist on GitHub. Import
# blocks run inside the normal plan/apply, so no manual `terraform import` is
# needed on the workspace. Remove this file once the apply has gone through.

import {
  to = module.repositories["profile"].github_repository.this
  id = "mainman94"
}

import {
  to = module.repositories["profile"].github_branch_default.this[0]
  id = "mainman94"
}

import {
  to = module.repositories["stoicful"].github_repository.this
  id = "stoicful"
}

import {
  to = module.repositories["stoicful"].github_branch_default.this[0]
  id = "stoicful"
}

import {
  to = module.repositories["beartainer"].github_repository.this
  id = "beartainer"
}

import {
  to = module.repositories["beartainer"].github_branch_default.this[0]
  id = "beartainer"
}

# Created in the UI as "Branch-Rule"; the apply renames it to
# default-branch-protection.
import {
  to = module.repositories["multi_k8s_infra"].github_repository_ruleset.this["default_branch"]
  id = "multi-k8s-infra:11212352"
}
