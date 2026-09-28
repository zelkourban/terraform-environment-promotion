variable "name" {
  description = "Bucket name. Must already be prefixed with project/environment by the caller."
  type        = string
}

variable "environment" {
  description = "Environment this bucket belongs to (dev | staging | prod)."
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment must be one of: dev, staging, prod."
  }
}

variable "versioning_enabled" {
  description = "Enable object versioning."
  type        = bool
  default     = true
}

variable "noncurrent_version_expiration_days" {
  description = "Days after which a noncurrent object version is deleted."
  type        = number
  default     = 90
}

variable "force_destroy" {
  description = "Allow Terraform to delete a non-empty bucket. Never true in prod."
  type        = bool
  default     = false
}

variable "access_log_bucket" {
  description = "Target bucket for S3 server access logs. Null disables logging."
  type        = string
  default     = null
}

# Access is granted identity-side only — see README. There is deliberately no
# reader_role_arns / writer_role_arns input: two places to look for "who can
# read this bucket" is one too many.

variable "tags" {
  description = "Additional tags merged onto every resource."
  type        = map(string)
  default     = {}
}
