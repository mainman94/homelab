secret_domains = [
  "github",
  "smtp",
  "dockerhub",
]

domain_kv_access = {
  dockerhub = {
    github = ["pat/*"]
  }
}

k8s_auth_enabled = false
# k8s_auth_path    = "kubernetes"
# k8s_host         = "https://kubernetes.default.svc:443"
# k8s_ca_cert      = <<-EOT
# -----BEGIN CERTIFICATE-----
# REPLACE_ME
# -----END CERTIFICATE-----
# EOT

github_auth_enabled  = true
github_auth_path     = "github"
github_oidc_audience = "vault"

github_access_by_domain = {
  dockerhub = [
    { repository = "mainman94/portfolio" },
  ]
}
