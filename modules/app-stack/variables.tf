variable "project" {
  description = "Project slug used as the naming prefix."
  type        = string
}

variable "environment" {
  description = "Environment name (dev | staging | prod)."
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment must be one of: dev, staging, prod."
  }
}

variable "vpc_id" {
  description = "VPC to deploy into."
  type        = string
}

variable "subnet_id" {
  description = "Subnet for the instance."
  type        = string
}

variable "assign_public_ip" {
  description = "Assign a public IP so the SSM agent can reach Systems Manager without NAT or interface endpoints. Ingress rules are empty either way."
  type        = bool
  default     = false
}

variable "instance_type" {
  description = "EC2 instance type."
  type        = string
  default     = "t3.micro"
}

variable "root_volume_size" {
  description = "Root EBS volume size in GiB."
  type        = number
  default     = 20
}

variable "bucket_suffix" {
  description = "Suffix appended to the generated bucket name, for global uniqueness."
  type        = string
  default     = "data"
}

variable "noncurrent_version_expiration_days" {
  description = "Days after which a noncurrent object version is deleted."
  type        = number
  default     = 90
}

variable "access_log_bucket" {
  description = "Target bucket for S3 server access logs."
  type        = string
  default     = null
}

variable "tags" {
  description = "Additional tags merged onto every resource."
  type        = map(string)
  default     = {}
}
