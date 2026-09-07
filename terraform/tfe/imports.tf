# Imports for existing Terraform Cloud workspaces in eggenberg-homelab.
# Using Terraform 1.5+ import blocks enables declarative adoption into state.
#
# Workspaces:
import {
  to = tfe_workspace.this["cloudflare"]
  id = "eggenberg-homelab/cloudflare"
}

import {
  to = tfe_workspace.this["github"]
  id = "eggenberg-homelab/github"
}

import {
  to = tfe_workspace.this["backblaze"]
  id = "eggenberg-homelab/backblaze"
}

import {
  to = tfe_workspace.this["openbao"]
  id = "eggenberg-homelab/openbao"
}

import {
  to = tfe_workspace.this["pocket-id"]
  id = "eggenberg-homelab/pocket-id"
}

import {
  to = tfe_workspace.this["eggenberg-talos-cluster"]
  id = "eggenberg-homelab/eggenberg-talos-cluster"
}
