# prod

Additional controls that apply only here:

- **Separate AWS account.** The OIDC role `…-terraform-prod` is assumable only
  from the `prod` GitHub Environment (`sub: repo:acme/infrastructure:environment:prod`).
- **Required reviewers** on the `prod` GitHub Environment — the deploy job
  blocks until a human approves.
- **CODEOWNERS** review required on any change under `envs/prod/**`.
- **`allowed_account_ids`** in `providers.tf` aborts the run if credentials
  resolve to a non-prod account.
- **No `force_destroy`** on the bucket; `secure-bucket` hard-overrides it to
  `false` when `environment == "prod"`.
- **No destroy path in CI.** Decommissioning prod is done locally, by an
  admin, deliberately.

## Manual follow-ups not expressible in Terraform

- Enable MFA-delete on the bucket (requires root credentials and the AWS CLI).
- Confirm the KMS key policy is reviewed after the first apply.
