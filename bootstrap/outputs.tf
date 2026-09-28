output "state_bucket" {
  description = "Name of the Terraform state bucket. Goes in envs/<env>/backend.tf."
  value       = aws_s3_bucket.state.id
}

output "state_kms_key_arn" {
  description = "ARN of the key encrypting state."
  value       = aws_kms_key.state.arn
}

output "plan_role_arn" {
  description = "Set as TF_PLAN_ROLE_ARN on the `<env>-plan` GitHub Environment."
  value       = aws_iam_role.terraform_plan.arn
}

output "apply_role_arn" {
  description = "Set as TF_APPLY_ROLE_ARN on the `<env>` GitHub Environment."
  value       = aws_iam_role.terraform_apply.arn
}

output "account_id" {
  description = "Account this layer was applied to. Goes in envs/<env>/terraform.tfvars."
  value       = data.aws_caller_identity.current.account_id
}

# Everything the GitHub side needs, in one place.
output "github_setup" {
  description = "Copy these into the repository's Environment settings."
  value = {
    "${var.environment}-plan" = {
      TF_PLAN_ROLE_ARN   = aws_iam_role.terraform_plan.arn
      required_reviewers = false
    }
    "${var.environment}" = {
      TF_APPLY_ROLE_ARN  = aws_iam_role.terraform_apply.arn
      required_reviewers = var.environment != "dev"
    }
  }
}
