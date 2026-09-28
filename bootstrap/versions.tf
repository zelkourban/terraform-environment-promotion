terraform {
  required_version = ">= 1.10"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.60"
    }
  }

  # No backend block on purpose.
  #
  # This layer creates the bucket every other layer stores state in, so the
  # first run is necessarily local. Immediately afterwards the state is moved
  # into the bucket it just created:
  #
  #   terraform init -migrate-state -backend-config=backends/<env>.hcl
  #
  # From then on this is an ordinary remote-state root: reviewable, drift-
  # detectable, and not dependent on one person's laptop.
}

provider "aws" {
  region              = var.region
  allowed_account_ids = [var.account_id]

  default_tags {
    tags = {
      Project     = var.project
      Environment = var.environment
      ManagedBy   = "terraform"
      Layer       = "bootstrap"
    }
  }
}

data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}
