variable "vault_endpoint" {
  description = "OpenBao API address (e.g. https://openbao.example.com:8200)"
  type        = string
}

variable "vault_token" {
  description = "OpenBao token used by the Terraform Vault provider"
  type        = string
  sensitive   = true
}

variable "vault_skip_tls_verify" {
  description = "Skip TLS verification for OpenBao API access"
  type        = bool
  default     = false
}

variable "secret_domains" {
  description = "Namespaces/domains to manage, e.g. github, smtp, dockerhub"
  type        = set(string)
}

variable "k8s_auth_enabled" {
  description = "Enable Kubernetes auth backend and role setup per namespace"
  type        = bool
  default     = true
}

variable "k8s_auth_path" {
  description = "Kubernetes auth mount path in each namespace"
  type        = string
  default     = "kubernetes"
}

variable "k8s_disable_iss_validation" {
  description = "Disable Kubernetes token issuer validation (keep false unless required)"
  type        = bool
  default     = false
}

variable "k8s_host" {
  description = "Kubernetes API host URL used for Vault Kubernetes auth config"
  type        = string
  default     = null
}

variable "k8s_ca_cert" {
  description = "PEM encoded Kubernetes CA cert for Kubernetes auth config"
  type        = string
  default     = null
}

variable "k8s_token_reviewer_jwt" {
  description = "Token reviewer JWT for Kubernetes auth config (optional)"
  type        = string
  sensitive   = true
  default     = null
}

variable "k8s_access_by_domain" {
  description = "Map domain => list of allowed Kubernetes namespace/service-account bindings"
  type = map(list(object({
    namespace       = string
    service_account = string
  })))
  default = {}
}

variable "k8s_role_token_ttl" {
  description = "TTL for Kubernetes auth tokens (seconds)"
  type        = number
  default     = 3600
}

variable "k8s_role_token_max_ttl" {
  description = "Max TTL for Kubernetes auth tokens (seconds)"
  type        = number
  default     = 14400
}

variable "k8s_role_token_num_uses" {
  description = "Max number of uses for Kubernetes auth tokens (0 = unlimited)"
  type        = number
  default     = 0
}

variable "github_auth_enabled" {
  description = "Enable GitHub Actions OIDC auth backend and roles"
  type        = bool
  default     = true
}

variable "github_auth_path" {
  description = "GitHub JWT/OIDC auth mount path in each namespace"
  type        = string
  default     = "github"
}

variable "github_oidc_discovery_url" {
  description = "GitHub Actions OIDC discovery endpoint"
  type        = string
  default     = "https://token.actions.githubusercontent.com"
}

variable "github_bound_issuer" {
  description = "Expected issuer for GitHub OIDC tokens"
  type        = string
  default     = "https://token.actions.githubusercontent.com"
}

variable "github_oidc_audience" {
  description = "Expected audience for GitHub OIDC tokens"
  type        = string
  default     = "vault"
}

variable "github_repo_access_by_domain" {
  description = "Legacy map domain => GitHub repos allowed to access that domain (format: org/repo)"
  type        = map(set(string))
  default     = {}
}

variable "github_access_by_domain" {
  description = "Map domain => list of GitHub OIDC claim bindings (repository plus optional ref/environment)"
  type = map(list(object({
    repository  = string
    ref         = optional(string)
    environment = optional(string)
  })))
  default = {}
}

variable "github_role_token_ttl" {
  description = "TTL for GitHub OIDC auth tokens (seconds)"
  type        = number
  default     = 900
}

variable "github_role_token_max_ttl" {
  description = "Max TTL for GitHub OIDC auth tokens (seconds)"
  type        = number
  default     = 3600
}

variable "github_role_token_num_uses" {
  description = "Max number of uses for GitHub OIDC auth tokens"
  type        = number
  default     = 10
}

variable "domain_kv_access" {
  description = "Map domain => allowed KV subpaths for Kubernetes and GitHub roles (relative to kv/)"
  type = map(object({
    k8s    = optional(list(string))
    github = optional(list(string))
  }))
  default = {}
}
