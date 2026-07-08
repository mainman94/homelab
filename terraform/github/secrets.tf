data "vault_kv_secret_v2" "openrouter" {
  mount = "homelab"
  name  = "prod/openrouter"
}

resource "github_actions_secret" "multi_k8s_infra_openrouter_api_key" {
  repository  = var.repositories["multi_k8s_infra"].name
  secret_name = "OPENROUTER_API_KEY"

  value = data.vault_kv_secret_v2.openrouter.data["API_KEY"]

  depends_on = [module.repositories]
}
