data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}

locals {
  is_prod = var.environment == "prod"
}

# --------------------------------------------------------------------------
# Customer-managed KMS key
#
# A CMK rather than SSE-S3 so key usage is auditable and revocable per
# environment. Bucket keys are enabled below to keep KMS request cost flat.
# --------------------------------------------------------------------------
resource "aws_kms_key" "this" {
  description             = "SSE-KMS key for ${var.name}"
  enable_key_rotation     = true
  deletion_window_in_days = local.is_prod ? 30 : 7
  policy                  = data.aws_iam_policy_document.key.json

  tags = var.tags
}

data "aws_iam_policy_document" "key" {
  # Delegate to IAM. Without this statement the key is orphaned — key policies
  # are not additive with IAM, and a key nobody is named in cannot be used or
  # even deleted without AWS support.
  statement {
    sid       = "EnableAccountIAM"
    effect    = "Allow"
    actions   = ["kms:*"]
    resources = ["*"]

    principals {
      type        = "AWS"
      identifiers = ["arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
  }

  # S3 needs the key to encrypt on write and decrypt on read, but only on
  # behalf of this bucket in this account.
  statement {
    sid    = "AllowS3ForThisBucket"
    effect = "Allow"

    actions = [
      "kms:Decrypt",
      "kms:GenerateDataKey",
    ]

    resources = ["*"]

    principals {
      type        = "Service"
      identifiers = ["s3.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }

    condition {
      test     = "ArnLike"
      variable = "aws:SourceArn"
      values   = ["arn:${data.aws_partition.current.partition}:s3:::${var.name}"]
    }
  }

  # No blanket cross-account Deny here on purpose. `aws:PrincipalAccount` is
  # absent for service principals, so a StringNotEquals deny would match the
  # S3 statement above and lock the bucket out of its own key. The boundary is
  # already drawn: the only grants are account-root IAM delegation (which is
  # account-scoped) and S3 conditioned on aws:SourceAccount.
}

resource "aws_kms_alias" "this" {
  name          = "alias/${var.name}"
  target_key_id = aws_kms_key.this.key_id
}

# --------------------------------------------------------------------------
# Bucket
# --------------------------------------------------------------------------
resource "aws_s3_bucket" "this" {
  bucket        = var.name
  force_destroy = local.is_prod ? false : var.force_destroy

  tags = var.tags

  # `prevent_destroy` is not set here: lifecycle blocks cannot read variables,
  # so a single resource cannot be protected in prod and disposable in dev
  # without duplicating it behind a count. The protection prod actually relies
  # on is force_destroy = false above (destroy fails on a non-empty versioned
  # bucket) plus the CODEOWNERS rule on envs/prod.
}

# ACLs disabled entirely — ownership is the only access mechanism.
resource "aws_s3_bucket_ownership_controls" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_public_access_block" "this" {
  bucket = aws_s3_bucket.this.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.this.arn
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.this.id

  versioning_configuration {
    status = var.versioning_enabled ? "Enabled" : "Suspended"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "this" {
  bucket     = aws_s3_bucket.this.id
  depends_on = [aws_s3_bucket_versioning.this]

  rule {
    id     = "abort-incomplete-multipart-uploads"
    status = "Enabled"

    filter {}

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }

  rule {
    id     = "expire-noncurrent-versions"
    status = var.versioning_enabled ? "Enabled" : "Disabled"

    filter {}

    noncurrent_version_expiration {
      noncurrent_days = var.noncurrent_version_expiration_days
    }
  }
}

resource "aws_s3_bucket_logging" "this" {
  count = var.access_log_bucket == null ? 0 : 1

  bucket        = aws_s3_bucket.this.id
  target_bucket = var.access_log_bucket
  target_prefix = "s3-access/${var.name}/"
}

# --------------------------------------------------------------------------
# Bucket policy — deny-by-default hardening
# --------------------------------------------------------------------------
data "aws_iam_policy_document" "bucket" {
  # Reject anything not over TLS.
  statement {
    sid     = "DenyInsecureTransport"
    effect  = "Deny"
    actions = ["s3:*"]

    resources = [
      aws_s3_bucket.this.arn,
      "${aws_s3_bucket.this.arn}/*",
    ]

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }

  # Reject uploads that do not use this bucket's CMK.
  statement {
    sid       = "DenyUnencryptedObjectUploads"
    effect    = "Deny"
    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.this.arn}/*"]

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    condition {
      test     = "StringNotEquals"
      variable = "s3:x-amz-server-side-encryption"
      values   = ["aws:kms"]
    }
  }

  # Reject access from outside this account.
  statement {
    sid     = "DenyCrossAccountAccess"
    effect  = "Deny"
    actions = ["s3:*"]

    resources = [
      aws_s3_bucket.this.arn,
      "${aws_s3_bucket.this.arn}/*",
    ]

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    condition {
      test     = "StringNotEquals"
      variable = "aws:PrincipalAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }

  # No Allow statements. Access is granted identity-side — the instance
  # profile in modules/compute names this bucket's ARN and key ARN. Keeping
  # grants in exactly one place means "who can read this bucket" has one
  # answer, not two that can disagree.
}

resource "aws_s3_bucket_policy" "this" {
  bucket     = aws_s3_bucket.this.id
  policy     = data.aws_iam_policy_document.bucket.json
  depends_on = [aws_s3_bucket_public_access_block.this]
}
