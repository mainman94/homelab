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
