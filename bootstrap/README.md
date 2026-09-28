# bootstrap

Run once per AWS account, before any environment can be planned or applied.
This is the chicken-and-egg layer: it creates the things Terraform needs in
order to run with remote state and OIDC.

## What it creates

| Resource | Why |
|---|---|
| `acme-tfstate-<env>` bucket | Remote state. Versioned, SSE-KMS, TLS-only, `prevent_destroy`. |
| KMS key + alias | State contains resource attributes in the clear - it gets a CMK, not SSE-S3. |
| GitHub OIDC provider | Account-scoped. Replaces long-lived access keys entirely; there is no IAM user anywhere in this design. |
| `acme-terraform-<env>-plan` | Read-only. `ReadOnlyAccess` plus read on the state object. Runs on PRs, where the code is not yet reviewed. |
| `acme-terraform-<env>-apply` | Scoped writes: EC2, S3 under the project prefix, KMS, and IAM confined to `acme-<env>-*`. Explicitly **not** `AdministratorAccess`. |
| Monthly budget | $5 by default, alerts at 80% and 100%. Two budgets per account are free. |

### The control that makes promotion real

Each role's trust policy pins the OIDC `sub` claim with `StringEquals`:

```
plan role   ← repo:<owner>/<repo>:environment:<env>-plan
apply role  ← repo:<owner>/<repo>:environment:<env>
```

A job running in the `dev` GitHub Environment presents a token reading
`environment:dev`. That does not match the prod role's condition, so it cannot
assume it - regardless of what the workflow file says or who edited it. This
is the load-bearing control in the repository; approval gates are the visible
part, this is the part that holds.

`StringEquals`, never `StringLike` - a wildcard here would let any environment
assume any role, which is the single most common OIDC misconfiguration.

The apply role also carries an explicit `Deny` on its own role, the plan role
and the OIDC provider. The pipeline cannot rewrite its own permissions.

## State: local first, then migrated

This layer creates the bucket every other layer stores state in, so the first
run has nowhere remote to put its own state. It does not stay that way.

```bash
cd bootstrap

# 1. Fill in the account ID and repository
$EDITOR dev.tfvars

# 2. First run, local state
terraform init
terraform apply -var-file=dev.tfvars

# 3. Move state into the bucket it just created
terraform init -migrate-state -backend-config=backends/dev.hcl
rm -f terraform.tfstate terraform.tfstate.backup
```

Lands at `s3://acme-tfstate-dev/bootstrap/terraform.tfstate` - same bucket as
the environment state, different key. From then on this is an ordinary remote
root: reviewable, drift-detectable, changed by PR like anything else.

Keeping it local would put the only record of who can assume the production
role on one laptop. That is not a thing to lose.

## Credentials for the first run

New member accounts have no users and no root password set. Reach in through
the role Organizations creates automatically:

```bash
aws sts assume-role \
  --role-arn arn:aws:iam::<account-id>:role/OrganizationAccountAccessRole \
  --role-session-name bootstrap
```

Export the returned credentials, then run the apply above. Repeat for each of
the three accounts.

## After applying

```bash
terraform output github_setup
```

Create these GitHub Environments in the repository and set the variable on
each:

| Environment | Variable | Required reviewers |
|---|---|---|
| `dev-plan` | `TF_PLAN_ROLE_ARN` | no |
| `dev` | `TF_APPLY_ROLE_ARN` | no |
| `staging-plan` | `TF_PLAN_ROLE_ARN` | no |
| `staging` | `TF_APPLY_ROLE_ARN` | **yes** |
| `prod-plan` | `TF_PLAN_ROLE_ARN` | no |
| `prod` | `TF_APPLY_ROLE_ARN` | **yes** |

The `*-plan` environments are deliberately unprotected - they are read-only,
and gating them would block PR feedback behind a human.

> Environment protection rules require a public repository on GitHub Free.
> On a private repo they need Pro or Team, and without them the approval gates
> silently do not exist.

Then copy `account_id` into the matching `envs/<env>/terraform.tfvars`.

## Branch protection for `main`

- Require a pull request, 1+ approval, CODEOWNERS review.
- Require status checks: `validate`, and `plan (<env>)` for each environment.
- Require linear history; disallow force pushes and deletions.
- Include administrators.

## Teardown

Don't. The bucket holds every environment's state and costs pennies; the roles
and OIDC provider are free. Tear down `envs/*` instead - see the root README.
