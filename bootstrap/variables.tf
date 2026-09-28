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

variable "create_oidc_provider" {
  description = <<-EOT
    Create the GitHub OIDC provider in this account.

    Set false if the account already has one - the provider is account-scoped
    and a second one for the same issuer is rejected.
  EOT
  type        = bool
  default     = true
}

variable "monthly_budget_usd" {
  description = "Monthly cost budget. An alert is emailed at 80% and 100%. Null disables the budget."
  type        = number
  default     = 5
}

variable "budget_notification_email" {
  description = "Address that receives budget alerts."
  type        = string
  default     = null
}
