variable "project" {
  description = "Project slug used as the naming prefix."
  type        = string
  default     = "acme"
}

variable "environment" {
  description = "Environment this account hosts (dev | staging | prod)."
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment must be one of: dev, staging, prod."
  }
}

variable "region" {
  description = "AWS region."
  type        = string
}

variable "account_id" {
  description = "Target AWS account ID. Terraform aborts if credentials resolve elsewhere."
  type        = string
}

variable "github_repository" {
  description = "owner/repo allowed to assume the Terraform roles."
  type        = string

  validation {
    condition     = can(regex("^[^/]+/[^/]+$", var.github_repository))
    error_message = "github_repository must be in owner/repo form."
  }
}

variable "github_owner_id" {
  description = "Numeric GitHub owner ID, from `gh api repos/<owner>/<repo> --jq .owner.id`."
  type        = string
}

variable "github_repository_id" {
  description = "Numeric GitHub repository ID, from `gh api repos/<owner>/<repo> --jq .id`."
  type        = string
}

variable "create_oidc_provider" {
  description = <<-EOT
    Create the GitHub OIDC provider in this account.

    Set false if the account already has one - the provider is account-scoped
    and a second one for the same issuer is rejected.
  EOT
  type        = bool
  default     = true
}
