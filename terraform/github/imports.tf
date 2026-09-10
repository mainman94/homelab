# One-off import for a newly adopted repository that already exists on GitHub.
# Delete this file once `terraform apply` has gone through — see README.md.
import {
  to = module.repositories["docker_strapi"].github_repository.this
  id = "docker-strapi"
}
import {
  to = module.repositories["docker_strapi"].github_branch_default.this[0]
  id = "docker-strapi"
}

# The first apply for the .agents repository created it on GitHub but then
# failed on the allow_forking PATCH (PR #89), so it was never recorded in
# state. Import it instead of creating it again. The repo has no branches
# yet (no auto_init), so there is no github_branch_default to import.
import {
  to = module.repositories["agents"].github_repository.this
  id = ".agents"
}
