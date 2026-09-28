# prod

Additional controls that apply only here:

- **Separate AWS account.** The `acme-terraform-prod-apply` role is assumable
  only from the `prod` GitHub Environment, pinned by the OIDC `sub` claim
  `repo:zelkourban/terraform-environment-promotion:environment:prod`.
- **Required reviewers** on the `prod` GitHub Environment - the deploy job
  blocks until a human approves.
- **CODEOWNERS** marks `envs/prod/**` as warranting a second reviewer. Note
  that required-approvals is not enforced in branch protection - see the root
  README for why on a single-maintainer repository.
- **`allowed_account_ids`** in `providers.tf` aborts the run if credentials
  resolve to a non-prod account.
- **No `force_destroy`** on the bucket; `secure-bucket` hard-overrides it to
  `false` when `environment == "prod"`.
- **No destroy path in CI.** Decommissioning prod is done locally, by an
  admin, deliberately.

## Manual follow-ups not expressible in Terraform

- Enable MFA-delete on the bucket (requires root credentials and the AWS CLI).
- Confirm the KMS key policy is reviewed after the first apply.
