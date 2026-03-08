variable "GH_TOKEN" {
  description = "GitHub token with repository administration permissions."
  type        = string
  sensitive   = true
}

variable "github_owner" {
  description = "GitHub owner that contains the repository."
  type        = string
  default     = "mainman94"
}

variable "repository_name" {
  description = "Repository name to manage."
  type        = string
  default     = "homelab"
}

variable "repository_description" {
  description = "Repository description."
  type        = string
  default     = null
  nullable    = true
}

variable "repository_homepage_url" {
  description = "Repository homepage URL."
  type        = string
  default     = null
  nullable    = true
}

variable "repository_visibility" {
  description = "Repository visibility."
  type        = string
  default     = "public"
}

variable "repository_topics" {
  description = "Topics to manage on the repository."
  type        = set(string)
  default     = []
}

variable "repository_has_issues" {
  description = "Whether issues are enabled."
  type        = bool
  default     = true
}

variable "repository_has_projects" {
  description = "Whether projects are enabled."
  type        = bool
  default     = false
}

variable "repository_has_wiki" {
  description = "Whether the wiki is enabled."
  type        = bool
  default     = false
}

variable "repository_allow_merge_commit" {
  description = "Whether merge commits are allowed. Null leaves the provider default behavior unchanged."
  type        = bool
  default     = null
  nullable    = true
}

variable "repository_allow_squash_merge" {
  description = "Whether squash merges are allowed. Null leaves the provider default behavior unchanged."
  type        = bool
  default     = null
  nullable    = true
}

variable "repository_allow_rebase_merge" {
  description = "Whether rebase merges are allowed. Null leaves the provider default behavior unchanged."
  type        = bool
  default     = null
  nullable    = true
}

variable "repository_allow_auto_merge" {
  description = "Whether auto-merge is allowed. Null leaves the provider default behavior unchanged."
  type        = bool
  default     = null
  nullable    = true
}

variable "repository_delete_branch_on_merge" {
  description = "Whether merged branches are deleted automatically. Null leaves the provider default behavior unchanged."
  type        = bool
  default     = null
  nullable    = true
}

variable "repository_allow_update_branch" {
  description = "Whether pull requests can be updated with the base branch. Null leaves the provider default behavior unchanged."
  type        = bool
  default     = null
  nullable    = true
}

variable "repository_allow_forking" {
  description = "Whether the repository can be forked."
  type        = bool
  default     = true
}

variable "repository_archived" {
  description = "Whether the repository is archived."
  type        = bool
  default     = false
}

variable "repository_archive_on_destroy" {
  description = "Archive the repository instead of deleting it on terraform destroy."
  type        = bool
  default     = true
}

variable "repository_vulnerability_alerts" {
  description = "Whether vulnerability alerts are enabled. Null leaves the provider default behavior unchanged."
  type        = bool
  default     = null
  nullable    = true
}

variable "repository_default_branch" {
  description = "Default branch to manage."
  type        = string
  default     = "main"
}

variable "modules_repository_name" {
  description = "Repository name to manage for the shared Terraform modules repository."
  type        = string
  default     = "homelab-terraform-modules"
}

variable "modules_repository_description" {
  description = "Repository description for the shared Terraform modules repository."
  type        = string
  default     = null
  nullable    = true
}

variable "modules_repository_homepage_url" {
  description = "Repository homepage URL for the shared Terraform modules repository."
  type        = string
  default     = null
  nullable    = true
}

variable "modules_repository_visibility" {
  description = "Repository visibility for the shared Terraform modules repository."
  type        = string
  default     = "public"
}

variable "modules_repository_topics" {
  description = "Topics to manage on the shared Terraform modules repository."
  type        = set(string)
  default     = []
}

variable "modules_repository_has_issues" {
  description = "Whether issues are enabled on the shared Terraform modules repository."
  type        = bool
  default     = true
}

variable "modules_repository_has_projects" {
  description = "Whether projects are enabled on the shared Terraform modules repository."
  type        = bool
  default     = true
}

variable "modules_repository_has_wiki" {
  description = "Whether the wiki is enabled on the shared Terraform modules repository."
  type        = bool
  default     = true
}

variable "modules_repository_allow_merge_commit" {
  description = "Whether merge commits are allowed on the shared Terraform modules repository. Null leaves the provider default behavior unchanged."
  type        = bool
  default     = null
  nullable    = true
}

variable "modules_repository_allow_squash_merge" {
  description = "Whether squash merges are allowed on the shared Terraform modules repository. Null leaves the provider default behavior unchanged."
  type        = bool
  default     = null
  nullable    = true
}

variable "modules_repository_allow_rebase_merge" {
  description = "Whether rebase merges are allowed on the shared Terraform modules repository. Null leaves the provider default behavior unchanged."
  type        = bool
  default     = null
  nullable    = true
}

variable "modules_repository_allow_auto_merge" {
  description = "Whether auto-merge is allowed on the shared Terraform modules repository. Null leaves the provider default behavior unchanged."
  type        = bool
  default     = null
  nullable    = true
}

variable "modules_repository_delete_branch_on_merge" {
  description = "Whether merged branches are deleted automatically on the shared Terraform modules repository. Null leaves the provider default behavior unchanged."
  type        = bool
  default     = null
  nullable    = true
}

variable "modules_repository_allow_update_branch" {
  description = "Whether pull requests can be updated with the base branch on the shared Terraform modules repository. Null leaves the provider default behavior unchanged."
  type        = bool
  default     = null
  nullable    = true
}

variable "modules_repository_allow_forking" {
  description = "Whether the shared Terraform modules repository can be forked."
  type        = bool
  default     = true
}

variable "modules_repository_archived" {
  description = "Whether the shared Terraform modules repository is archived."
  type        = bool
  default     = false
}

variable "modules_repository_archive_on_destroy" {
  description = "Archive the shared Terraform modules repository instead of deleting it on terraform destroy."
  type        = bool
  default     = true
}

variable "modules_repository_vulnerability_alerts" {
  description = "Whether vulnerability alerts are enabled on the shared Terraform modules repository. Null leaves the provider default behavior unchanged."
  type        = bool
  default     = null
  nullable    = true
}

variable "modules_repository_default_branch" {
  description = "Default branch to manage for the shared Terraform modules repository."
  type        = string
  default     = "main"
}
