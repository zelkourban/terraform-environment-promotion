output "state_bucket" {
  description = "Name of the Terraform state bucket. Passed to init as -backend-config=\"bucket=...\"."
  value       = aws_s3_bucket.state.id
}

output "state_kms_key_arn" {
  description = "ARN of the key encrypting state."
  value       = aws_kms_key.state.arn
}

output "plan_role_arn" {
  description = "Read-only role assumed by the plan workflow. Built from the account ID in CI, not stored."
  value       = aws_iam_role.terraform_plan.arn
}

output "apply_role_arn" {
  description = "Role assumed by the apply workflow. Built from the account ID in CI, not stored."
  value       = aws_iam_role.terraform_apply.arn
}

output "account_id" {
  description = "Account this layer was applied to. Set as the AWS_ACCOUNT_ID secret on the <env> and <env>-plan GitHub Environments."
  value       = data.aws_caller_identity.current.account_id
}
