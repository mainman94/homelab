output "namespaces" {
  description = "Managed OpenBao namespaces"
  value       = [for ns in vault_namespace.domain : ns.path]
}

output "k8s_roles_by_domain" {
  description = "Kubernetes auth role names keyed by domain:namespace:serviceaccount"
  value = {
    for key, role in vault_kubernetes_auth_backend_role.k8s_reader : key => role.role_name
  }
}

output "github_roles" {
  description = "GitHub auth role names keyed by domain:org/repo:ref:environment"
  value = {
    for key, role in vault_jwt_auth_backend_role.github_reader : key => role.role_name
  }
}
