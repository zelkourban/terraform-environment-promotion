# `secure-bucket`

An S3 bucket that is private and encrypted by construction, not by convention.

## Contract

Given a name and an environment, the module guarantees:

- no public access (all four block-public settings on, ACLs disabled),
- SSE-KMS with a dedicated, rotating customer-managed key,
- a bucket policy denying non-TLS requests, unencrypted uploads and
  cross-account principals,
- versioning with noncurrent-version expiry,
- `force_destroy` forced to `false` when `environment == "prod"`.

Consumers are expected to grant themselves access **identity-side** (an IAM
role policy referencing `bucket_arn` and `kms_key_arn`), not by widening the
bucket policy.

## Usage

```hcl
module "data" {
  source = "../../modules/secure-bucket"

  name        = "acme-dev-data-123456789012"
  environment = "dev"
  tags        = local.tags
}
```

## Inputs / outputs

See `variables.tf` and `outputs.tf`.
