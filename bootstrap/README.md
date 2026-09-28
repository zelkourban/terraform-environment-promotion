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

No budget is created here. Member accounts are made with IAM billing access
denied, so `CreateBudget` is refused inside them; under consolidated billing
the payer account is the right place for one anyway.

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

# The account ID is never committed - it is an input, and it names the
# bucket this layer is about to create.
export TF_VAR_account_id=<dev account id>

# 1. First run: shadow the S3 backend with a local one, since the bucket
#    this layer is about to create does not exist yet. *_override.tf is
#    gitignored and merges over the backend block in versions.tf.
printf 'terraform {\n  backend "local" {}\n}\n' > backend_override.tf
terraform init
terraform apply -var-file=dev.tfvars
rm backend_override.tf

# 2. Move state into the bucket it just created
terraform init -migrate-state \
  -backend-config=backends/dev.hcl \
  -backend-config="bucket=acme-tfstate-dev-$TF_VAR_account_id"
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

Create these GitHub Environments and set one secret on each:

| Environment | Secret | Required reviewers |
|---|---|---|
| `dev-plan` | `AWS_ACCOUNT_ID` | no |
| `dev` | `AWS_ACCOUNT_ID` | no |
| `staging-plan` | `AWS_ACCOUNT_ID` | no |
| `staging` | `AWS_ACCOUNT_ID` | **yes** |
| `prod-plan` | `AWS_ACCOUNT_ID` | no |
| `prod` | `AWS_ACCOUNT_ID` | **yes** |

The role ARNs are not stored anywhere. Workflows build them from the account
ID and the environment name:

```
arn:aws:iam::$AWS_ACCOUNT_ID:role/acme-terraform-<env>-{plan,apply}
```

A secret rather than a variable because GitHub prints step inputs in job
logs - a variable would put the account ID straight into a public log, while
a secret is masked wherever it appears, including inside an ARN.

The `*-plan` environments are deliberately unprotected - they are read-only,
and gating them would block PR feedback behind a human.

> Environment protection rules require a public repository on GitHub Free.
> On a private repo they need Pro or Team, and without them the approval gates
> silently do not exist.

Also set `AWS_ACCOUNT_ID` as a **secret** on both `<env>` and `<env>-plan`.
The workflows use it for `TF_VAR_account_id` and to name the state bucket in
the partial backend configuration. A secret rather than a variable so GitHub
masks it in job logs.

## Branch protection for `main`

- Require a pull request, 1+ approval, CODEOWNERS review.
- Require status checks: `validate`, and `plan (<env>)` for each environment.
- Require linear history; disallow force pushes and deletions.
- Include administrators.

## Teardown

Don't. The bucket holds every environment's state and costs pennies; the roles
and OIDC provider are free. Tear down `envs/*` instead - see the root README.
