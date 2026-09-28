terraform {
  required_version = ">= 1.10"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.60"
    }
  }

  # Partial backend configuration - every value comes from backends/<env>.hcl
  # and the -backend-config flag, because the bucket name embeds the account
  # ID and is not committed.
  #
  # This layer creates the bucket it stores state in, so the first run has to
  # skip the backend entirely and then migrate:
  #
  #   terraform init -backend=false
  #   terraform apply -var-file=<env>.tfvars
  #   terraform init -migrate-state \
  #     -backend-config=backends/<env>.hcl \
  #     -backend-config="bucket=acme-tfstate-<env>-$TF_VAR_account_id"
  #
  # From then on this is an ordinary remote-state root: reviewable, drift-
  # detectable, and not dependent on one person's laptop.
  backend "s3" {}
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
