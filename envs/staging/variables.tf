variable "project" {
  description = "Project slug used as the naming prefix."
  type        = string
  default     = "acme"
}

variable "environment" {
  description = "Environment name."
  type        = string
  default     = "staging"
}

variable "region" {
  description = "AWS region."
  type        = string
}

variable "account_id" {
  description = "Expected AWS account ID. Terraform aborts if credentials resolve elsewhere."
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type."
  type        = string
}

variable "root_volume_size" {
  description = "Root EBS volume size in GiB."
  type        = number
  default     = 20
}

variable "assign_public_ip" {
  description = <<-EOT
    Give the instance a public IP so the SSM agent can reach Systems Manager
    over the internet gateway.

    This is the low-cost path and the security posture is unchanged - the
    security group still has no ingress rules at all. A production deployment
    sets this false and provides a private subnet with a NAT gateway or SSM
    interface endpoints.
  EOT
  type        = bool
  default     = false
}

variable "noncurrent_version_expiration_days" {
  description = "Days after which a noncurrent object version is deleted."
  type        = number
  default     = 30
}
