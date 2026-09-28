variable "name" {
  description = "Instance name. Already prefixed with project/environment by the caller."
  type        = string
}

variable "environment" {
  description = "Environment this instance belongs to (dev | staging | prod)."
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment must be one of: dev, staging, prod."
  }
}

variable "instance_type" {
  description = "EC2 instance type."
  type        = string
  default     = "t3.micro"
}

variable "subnet_id" {
  description = "Private subnet to launch into."
  type        = string
}

variable "vpc_id" {
  description = "VPC of the target subnet."
  type        = string
}

variable "root_volume_size" {
  description = "Root EBS volume size in GiB."
  type        = number
  default     = 20
}

variable "assign_public_ip" {
  description = <<-EOT
    Assign a public IP so the SSM agent can reach Systems Manager over an
    internet gateway, instead of requiring NAT or SSM interface endpoints.

    The security group has no ingress rules either way — this changes
    reachability of the agent, not exposure of the instance.
  EOT
  type        = bool
  default     = false
}

variable "bucket_arn" {
  description = "ARN of the bucket this instance may read/write."
  type        = string
}

variable "bucket_kms_key_arn" {
  description = "ARN of the CMK encrypting that bucket."
  type        = string
}

variable "tags" {
  description = "Additional tags merged onto every resource."
  type        = map(string)
  default     = {}
}
