# super-intelligence was created by hand before its first apply, so the
# provider's create failed with "name already exists". Adopt it instead.
# Delete this file once the apply has gone through.
import {
  to = module.repositories["super_intelligence"].github_repository.this
  id = "super-intelligence"
}
