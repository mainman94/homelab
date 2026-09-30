# The first apply of super-intelligence-mcp created it, failed on the
# allow_forking PATCH and left it tainted; the next apply "replaced" it, which
# archived the repository (archive_on_destroy) and dropped it from state. It
# has been unarchived by hand; adopt it again. See README "Adding a private
# repository". Delete this file once the apply has gone through.
import {
  to = module.repositories["super_intelligence_mcp"].github_repository.this
  id = "super-intelligence-mcp"
}
