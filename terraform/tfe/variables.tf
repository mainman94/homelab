variable "organization" {
  description = "Terraform Cloud organization name"
  type        = string
  default     = "eggenberg-homelab"
}

variable "agent_pool_id" {
  description = "Agent pool ID (e.g. apool-xxx) for agent-executed workspaces"
  type        = string
  default     = "apool-QA5S8U2ZmmRMujGd"
}

variable "vcs_repo_identifier" {
  description = "GitHub repository identifier in 'org/repo' format for VCS integration"
  type        = string
  default     = "mainman94/homelab"
}

variable "github_app_installation_id" {
  description = "GitHub App installation ID (ghain-xxx) backing the VCS connection for workspaces in this org"
  type        = string
  default     = "ghain-JGyg1guxS3fD1GPu"
}

variable "vault_address" {
  description = "OpenBao address reachable by HCP runners / agents"
  type        = string
  default     = "http://192.168.0.129:30020"
}

variable "terraform_version" {
  description = "Terraform version pinned for all managed workspaces"
  type        = string
  default     = "1.16.1"
}

variable "module_repo_identifier" {
  description = "GitHub repository identifier holding the private Terraform modules, in 'org/repo' format"
  type        = string
  default     = "mainman94/homelab-terraform-modules"
}
