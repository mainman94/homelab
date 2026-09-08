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

import {
  to = tfe_workspace.this["tfe"]
  id = "eggenberg-homelab/tfe"
}

import {
  to = tfe_workspace_settings.this["cloudflare"]
  id = "eggenberg-homelab/cloudflare"
}

import {
  to = tfe_workspace_settings.this["github"]
  id = "eggenberg-homelab/github"
}

import {
  to = tfe_workspace_settings.this["backblaze"]
  id = "eggenberg-homelab/backblaze"
}

import {
  to = tfe_workspace_settings.this["openbao"]
  id = "eggenberg-homelab/openbao"
}

import {
  to = tfe_workspace_settings.this["pocket-id"]
  id = "eggenberg-homelab/pocket-id"
}

import {
  to = tfe_workspace_settings.this["eggenberg-talos-cluster"]
  id = "eggenberg-homelab/eggenberg-talos-cluster"
}

import {
  to = tfe_workspace_settings.this["tfe"]
  id = "eggenberg-homelab/tfe"
}

# Workload-identity env vars already set manually in TFC — imported so this
# stack adopts them instead of colliding on create.
import {
  to = tfe_variable.vault_auth["backblaze_TFC_VAULT_RUN_ROLE"]
  id = "eggenberg-homelab/backblaze/var-qaHFTBuptsQZGwGX"
}

import {
  to = tfe_variable.vault_auth["backblaze_TFC_VAULT_AUTH_PATH"]
  id = "eggenberg-homelab/backblaze/var-yngAwKdWUA6GwGNR"
}

import {
  to = tfe_variable.vault_auth["backblaze_TFC_VAULT_ADDR"]
  id = "eggenberg-homelab/backblaze/var-K7rZm9aSqNxQbS4x"
}

import {
  to = tfe_variable.vault_auth["backblaze_TFC_VAULT_PROVIDER_AUTH"]
  id = "eggenberg-homelab/backblaze/var-vKA91xxDu8ZBziWk"
}

import {
  to = tfe_variable.vault_auth["cloudflare_TFC_VAULT_AUTH_PATH"]
  id = "eggenberg-homelab/cloudflare/var-b1xPMWyNZHkxAtpn"
}

import {
  to = tfe_variable.vault_auth["cloudflare_TFC_VAULT_PROVIDER_AUTH"]
  id = "eggenberg-homelab/cloudflare/var-aRxETc9ndztGYxWh"
}

import {
  to = tfe_variable.vault_auth["cloudflare_TFC_VAULT_RUN_ROLE"]
  id = "eggenberg-homelab/cloudflare/var-UndczXkhegXmhzux"
}

import {
  to = tfe_variable.vault_auth["cloudflare_TFC_VAULT_ADDR"]
  id = "eggenberg-homelab/cloudflare/var-4LVMkSvVadPoG3dc"
}

import {
  to = tfe_variable.vault_auth["github_TFC_VAULT_PROVIDER_AUTH"]
  id = "eggenberg-homelab/github/var-sTRVnDbbpAA25ihz"
}

import {
  to = tfe_variable.vault_auth["github_TFC_VAULT_RUN_ROLE"]
  id = "eggenberg-homelab/github/var-rk1SHo4z592iiVbX"
}

import {
  to = tfe_variable.vault_auth["github_TFC_VAULT_AUTH_PATH"]
  id = "eggenberg-homelab/github/var-QJB7USqpmohede6m"
}

import {
  to = tfe_variable.vault_auth["github_TFC_VAULT_ADDR"]
  id = "eggenberg-homelab/github/var-eewD8Fgh7g4qF1yK"
}

import {
  to = tfe_variable.vault_auth["pocket-id_TFC_VAULT_ADDR"]
  id = "eggenberg-homelab/pocket-id/var-xtExYMsVMWCEPYfg"
}

import {
  to = tfe_variable.vault_auth["pocket-id_TFC_VAULT_AUTH_PATH"]
  id = "eggenberg-homelab/pocket-id/var-5wf6tnKqgyuS295x"
}

import {
  to = tfe_variable.vault_auth["pocket-id_TFC_VAULT_PROVIDER_AUTH"]
  id = "eggenberg-homelab/pocket-id/var-a3yjmMKDLSoN4iKp"
}

import {
  to = tfe_variable.vault_auth["pocket-id_TFC_VAULT_RUN_ROLE"]
  id = "eggenberg-homelab/pocket-id/var-sx77SEuWWTS4riuf"
}
