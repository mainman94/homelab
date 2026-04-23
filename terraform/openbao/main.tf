locals {
  domains = {
    for domain in var.secret_domains : domain => domain
  }

  domain_access = {
    for domain in var.secret_domains : domain => {
      k8s_paths    = try(var.domain_kv_access[domain].k8s, ["runtime/*"])
      github_paths = try(var.domain_kv_access[domain].github, ["ci/*"])
    }
  }

  github_access_legacy = flatten([
    for domain, repos in var.github_repo_access_by_domain : [
      for repo in repos : {
        domain      = domain
        repository  = repo
        ref         = null
        environment = null
      }
    ] if contains(var.secret_domains, domain)
  ])

  github_access_typed = flatten([
    for domain, bindings in var.github_access_by_domain : [
      for binding in bindings : {
        domain      = domain
        repository  = binding.repository
        ref         = try(binding.ref, null)
        environment = try(binding.environment, null)
      }
    ] if contains(var.secret_domains, domain)
  ])

  github_access_effective = length(local.github_access_typed) > 0 ? local.github_access_typed : local.github_access_legacy

  github_role_bindings = [
    for binding in local.github_access_effective : {
      key         = "${binding.domain}:${binding.repository}:${coalesce(binding.ref, "*")}:${coalesce(binding.environment, "*")}"
      domain      = binding.domain
      repository  = binding.repository
      ref         = binding.ref
      environment = binding.environment
      role_name   = "gha-${binding.domain}-${replace(binding.repository, "/", "-")}-${substr(md5("${coalesce(binding.ref, "*")}:${coalesce(binding.environment, "*")}"), 0, 8)}-read"
    }
  ]

  github_domains = toset([
    for binding in local.github_role_bindings : binding.domain
  ])

  github_domain_map = {
    for domain in local.github_domains : domain => domain
  }

  k8s_role_bindings = flatten([
    for domain, bindings in var.k8s_access_by_domain : [
      for binding in bindings : {
        key             = "${domain}:${binding.namespace}:${binding.service_account}"
        domain          = domain
        k8s_namespace   = binding.namespace
        service_account = binding.service_account
      }
    ] if contains(var.secret_domains, domain)
  ])

  k8s_domains = toset([
    for binding in local.k8s_role_bindings : binding.domain
  ])

  k8s_domain_map = {
    for domain in local.k8s_domains : domain => domain
  }
}

resource "vault_namespace" "domain" {
  for_each = local.domains

  path = each.key

  lifecycle {
    prevent_destroy = true
  }
}

resource "vault_mount" "kv" {
  for_each = local.domains

  namespace   = vault_namespace.domain[each.key].path
  path        = "kv"
  type        = "kv-v2"
  description = "Domain secrets for ${each.key}"

  lifecycle {
    prevent_destroy = true
  }
}

resource "vault_policy" "k8s_read" {
  for_each = var.k8s_auth_enabled ? local.k8s_domain_map : {}

  namespace = vault_namespace.domain[each.key].path
  name      = "k8s-${each.key}-read"
  policy = join("\n\n", [
    for path_pattern in local.domain_access[each.key].k8s_paths : <<-EOT
      path "kv/data/${path_pattern}" {
        capabilities = ["read"]
      }

      path "kv/metadata/${path_pattern}" {
        capabilities = ["read", "list"]
      }
    EOT
  ])
}

resource "vault_policy" "github_read" {
  for_each = var.github_auth_enabled ? local.github_domain_map : {}

  namespace = vault_namespace.domain[each.key].path
  name      = "github-${each.key}-read"
  policy = join("\n\n", [
    for path_pattern in local.domain_access[each.key].github_paths : <<-EOT
      path "kv/data/${path_pattern}" {
        capabilities = ["read"]
      }

      path "kv/metadata/${path_pattern}" {
        capabilities = ["read", "list"]
      }
    EOT
  ])
}

resource "vault_auth_backend" "kubernetes" {
  for_each = var.k8s_auth_enabled ? local.k8s_domain_map : {}

  namespace = vault_namespace.domain[each.key].path
  type      = "kubernetes"
  path      = var.k8s_auth_path

  lifecycle {
    prevent_destroy = true
  }
}

resource "vault_kubernetes_auth_backend_config" "kubernetes" {
  for_each = var.k8s_auth_enabled ? local.k8s_domain_map : {}

  namespace              = vault_namespace.domain[each.key].path
  backend                = vault_auth_backend.kubernetes[each.key].path
  kubernetes_host        = var.k8s_host
  kubernetes_ca_cert     = var.k8s_ca_cert
  token_reviewer_jwt     = var.k8s_token_reviewer_jwt
  disable_iss_validation = var.k8s_disable_iss_validation
}

resource "vault_kubernetes_auth_backend_role" "k8s_reader" {
  for_each = var.k8s_auth_enabled ? {
    for binding in local.k8s_role_bindings : binding.key => binding
  } : {}

  namespace = vault_namespace.domain[each.value.domain].path
  backend   = vault_auth_backend.kubernetes[each.value.domain].path
  role_name = "k8s-${each.value.domain}-${replace(each.value.k8s_namespace, "/", "-")}-${replace(each.value.service_account, "/", "-")}-read"
  bound_service_account_names = [
    each.value.service_account
  ]
  bound_service_account_namespaces = [
    each.value.k8s_namespace
  ]
  token_policies = [vault_policy.k8s_read[each.value.domain].name]
  token_ttl      = var.k8s_role_token_ttl
  token_max_ttl  = var.k8s_role_token_max_ttl
  token_num_uses = var.k8s_role_token_num_uses
}

resource "vault_jwt_auth_backend" "github" {
  for_each = var.github_auth_enabled ? local.github_domain_map : {}

  namespace          = vault_namespace.domain[each.key].path
  path               = var.github_auth_path
  oidc_discovery_url = var.github_oidc_discovery_url
  bound_issuer       = var.github_bound_issuer

  lifecycle {
    prevent_destroy = true
  }
}

resource "vault_jwt_auth_backend_role" "github_reader" {
  for_each = var.github_auth_enabled ? {
    for binding in local.github_role_bindings : binding.key => binding
  } : {}

  namespace       = vault_namespace.domain[each.value.domain].path
  backend         = vault_jwt_auth_backend.github[each.value.domain].path
  role_name       = each.value.role_name
  role_type       = "jwt"
  user_claim      = "repository"
  bound_audiences = [var.github_oidc_audience]
  bound_claims = merge(
    {
      repository       = each.value.repository
      repository_owner = split("/", each.value.repository)[0]
    },
    each.value.ref != null ? { ref = each.value.ref } : {},
    each.value.environment != null ? { environment = each.value.environment } : {}
  )
  bound_claims_type = "string"
  token_policies    = [vault_policy.github_read[each.value.domain].name]
  token_ttl         = var.github_role_token_ttl
  token_max_ttl     = var.github_role_token_max_ttl
  token_num_uses    = var.github_role_token_num_uses
}
