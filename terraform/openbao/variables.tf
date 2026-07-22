variable "vault_address" {
  description = "OpenBao API address"
  type        = string
  default     = "http://192.168.0.129:30020"
}

variable "tfc_organization" {
  description = "HCP Terraform organization that owns the consumer workspaces"
  type        = string
  default     = "eggenberg-homelab"
}

variable "tfc_vault_audience" {
  description = "Bound audience for HCP Terraform workload-identity tokens (HCP default: vault.workload.identity)"
  type        = string
  default     = "vault.workload.identity"
}

variable "github_actions_vault_audience" {
  description = "Bound audience for GitHub Actions OIDC tokens (GitHub default: the repo owner URL)"
  type        = string
  default     = "https://github.com/mainman94"
}

variable "kv_mount" {
  description = "kv-v2 secrets engine mount path"
  type        = string
  default     = "homelab"
}

variable "kubernetes_host" {
  description = "Cluster API endpoint reachable from the OpenBao Docker host"
  type        = string
  default     = "https://192.168.0.10:6443"
}

variable "kubernetes_ca_cert" {
  description = "PEM CA cert for the cluster API"
  type        = string
  sensitive   = true
}

variable "token_reviewer_jwt" {
  description = "JWT of the openbao-reviewer ServiceAccount (system:auth-delegator), used by OpenBao to call the TokenReview API"
  type        = string
  sensitive   = true
}

variable "eso_sa_name" {
  description = "Kubernetes ServiceAccount name bound to the reader role (External Secrets Operator)"
  type        = string
  default     = "external-secrets"
}

variable "eso_namespace" {
  description = "Namespace of the bound ServiceAccount"
  type        = string
  default     = "external-secrets"
}
