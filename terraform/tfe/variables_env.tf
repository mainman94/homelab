# Workload-identity environment variables for OpenBao / Vault authentication.
# Enables short-lived OIDC tokens per run instead of static VAULT_TOKEN.

locals {
  # Consumer workspaces requiring OpenBao workload identity:
  vault_workspaces = {
    for k, v in local.workspaces : k => v
    if v.vault_run_role != null
  }

  vault_vars = {
    for pair in flatten([
      for ws_name, ws_config in local.vault_workspaces : [
        {
          key          = "${ws_name}_TFC_VAULT_PROVIDER_AUTH"
          workspace_id = tfe_workspace.this[ws_name].id
          var_key      = "TFC_VAULT_PROVIDER_AUTH"
          var_value    = "true"
          category     = "env"
          description  = "Enable HCP workload identity token injection for Vault"
        },
        {
          key          = "${ws_name}_TFC_VAULT_ADDR"
          workspace_id = tfe_workspace.this[ws_name].id
          var_key      = "TFC_VAULT_ADDR"
          var_value    = var.vault_address
          category     = "env"
          description  = "Vault/OpenBao address"
        },
        {
          key          = "${ws_name}_TFC_VAULT_AUTH_PATH"
          workspace_id = tfe_workspace.this[ws_name].id
          var_key      = "TFC_VAULT_AUTH_PATH"
          var_value    = "tfc"
          category     = "env"
          description  = "Mount path of the Vault JWT auth engine"
        },
        {
          key          = "${ws_name}_TFC_VAULT_RUN_ROLE"
          workspace_id = tfe_workspace.this[ws_name].id
          var_key      = "TFC_VAULT_RUN_ROLE"
          var_value    = ws_config.vault_run_role
          category     = "env"
          description  = "Vault JWT role bound to this workspace"
        }
      ]
    ]) : pair.key => pair
  }
}

resource "tfe_variable" "vault_auth" {
  for_each = local.vault_vars

  workspace_id = each.value.workspace_id
  key          = each.value.var_key
  value        = each.value.var_value
  category     = each.value.category
  description  = each.value.description
  sensitive    = false
}
