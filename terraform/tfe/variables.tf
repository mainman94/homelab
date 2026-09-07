variable "organization" {
  description = "Terraform Cloud organization name"
  type        = string
  default     = "eggenberg-homelab"
}

variable "agent_pool_id" {
  description = "Agent pool ID (e.g. apool-xxx). If provided, skips looking up the pool by name via data source."
  type        = string
  default     = "apool-QA5S8U2ZmmRMujGd"
}

variable "agent_pool_name" {
  description = "Name of the existing agent pool for agent-executed workspaces (used if agent_pool_id is null)"
  type        = string
  default     = "homelab-eggenberg"
}

variable "vcs_repo_identifier" {
  description = "GitHub repository identifier in 'org/repo' format for VCS integration"
  type        = string
  default     = "mainman94/homelab"
}

variable "oauth_token_id" {
  description = "OAuth token ID for VCS connection in Terraform Cloud (optional, leave null to manage workspaces without VCS integration or if configured out-of-band)"
  type        = string
  default     = null
  sensitive   = true
}

variable "vault_address" {
  description = "OpenBao address reachable by HCP runners / agents"
  type        = string
  default     = "http://192.168.0.129:30020"
}
