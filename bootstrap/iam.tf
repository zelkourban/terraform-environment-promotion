locals {
  oidc_issuer = "token.actions.githubusercontent.com"

  oidc_provider_arn = var.create_oidc_provider ? (
    aws_iam_openid_connect_provider.github[0].arn
    ) : (
    "arn:${data.aws_partition.current.partition}:iam::${var.account_id}:oidc-provider/${local.oidc_issuer}"
  )

  # GitHub's immutable subject claim embeds the numeric owner and repo IDs:
  #   repo:<owner>@<owner_id>/<repo>@<repo_id>:environment:<env>
  # Pinning the IDs means a rename or recreate does not transfer trust.
  repo_subject = format(
    "repo:%s@%s/%s@%s",
    split("/", var.github_repository)[0], var.github_owner_id,
    split("/", var.github_repository)[1], var.github_repository_id,
  )

  apply_subject = "${local.repo_subject}:environment:${var.environment}"
  plan_subject  = "${local.repo_subject}:environment:${var.environment}-plan"

  state_key_arn = "${aws_s3_bucket.state.arn}/env/${var.environment}/terraform.tfstate"
}

# Account-scoped and single-instance per issuer.
resource "aws_iam_openid_connect_provider" "github" {
  count = var.create_oidc_provider ? 1 : 0

  url            = "https://${local.oidc_issuer}"
  client_id_list = ["sts.amazonaws.com"]

  # AWS populates and rotates this itself for well-known IdPs; pinning a value
  # would expire, and not ignoring it reports drift on every rotation.
  thumbprint_list = []

  lifecycle {
    ignore_changes = [thumbprint_list]
  }
}

# The `sub` condition is the control the whole promotion model rests on: a job
# running as dev presents `:environment:dev` and cannot match the prod role.
# StringEquals, never StringLike - a wildcard would let any environment in.
data "aws_iam_policy_document" "assume_plan" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [local.oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.oidc_issuer}:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.oidc_issuer}:sub"
      values   = [local.plan_subject]
    }
  }
}

data "aws_iam_policy_document" "assume_apply" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [local.oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.oidc_issuer}:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.oidc_issuer}:sub"
      values   = [local.apply_subject]
    }
  }
}

# Runs on pull requests, where the code is not yet reviewed. Reads state and
# describes resources, writes nothing; plan uses -lock=false so it need not.
resource "aws_iam_role" "terraform_plan" {
  name                 = "${var.project}-terraform-${var.environment}-plan"
  description          = "Read-only Terraform plan role for ${var.environment}"
  assume_role_policy   = data.aws_iam_policy_document.assume_plan.json
  max_session_duration = 3600
}

resource "aws_iam_role_policy_attachment" "plan_readonly" {
  role       = aws_iam_role.terraform_plan.name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/ReadOnlyAccess"
}

data "aws_iam_policy_document" "plan_state" {
  statement {
    sid       = "ReadStateObject"
    effect    = "Allow"
    actions   = ["s3:GetObject"]
    resources = [local.state_key_arn]
  }

  statement {
    sid       = "ListStateBucket"
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.state.arn]
  }

  statement {
    sid       = "DecryptState"
    effect    = "Allow"
    actions   = ["kms:Decrypt", "kms:DescribeKey"]
    resources = [aws_kms_key.state.arn]
  }
}

resource "aws_iam_role_policy" "plan_state" {
  name   = "terraform-state-read"
  role   = aws_iam_role.terraform_plan.id
  policy = data.aws_iam_policy_document.plan_state.json
}

# Deliberately not AdministratorAccess: a mistaken apply must not be able to
# mint IAM principals outside the project prefix or touch the pipeline's roles.
resource "aws_iam_role" "terraform_apply" {
  name                 = "${var.project}-terraform-${var.environment}-apply"
  description          = "Terraform apply role for ${var.environment}"
  assume_role_policy   = data.aws_iam_policy_document.assume_apply.json
  max_session_duration = 3600
}

data "aws_iam_policy_document" "apply" {
  statement {
    sid    = "StateReadWrite"
    effect = "Allow"

    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
    ]

    resources = [
      local.state_key_arn,
      "${local.state_key_arn}.tflock",
    ]
  }

  statement {
    sid       = "ListStateBucket"
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.state.arn]
  }

  statement {
    sid    = "StateKey"
    effect = "Allow"

    actions = [
      "kms:Decrypt",
      "kms:Encrypt",
      "kms:GenerateDataKey",
      "kms:DescribeKey",
    ]

    resources = [aws_kms_key.state.arn]
  }

  # Read-everything so plan can refresh; writes are enumerated below.
  statement {
    sid    = "Describe"
    effect = "Allow"

    actions = [
      "ec2:Describe*",
      "s3:Get*",
      "s3:List*",
      "kms:Describe*",
      "kms:List*",
      "kms:Get*",
      "iam:Get*",
      "iam:List*",
      "sts:GetCallerIdentity",
      "tag:Get*",
    ]

    resources = ["*"]
  }

  statement {
    sid    = "Compute"
    effect = "Allow"

    actions = [
      "ec2:RunInstances",
      "ec2:TerminateInstances",
      "ec2:StartInstances",
      "ec2:StopInstances",
      "ec2:ModifyInstanceAttribute",
      "ec2:ModifyInstanceMetadataOptions",
      "ec2:MonitorInstances",
      "ec2:UnmonitorInstances",
      "ec2:CreateTags",
      "ec2:DeleteTags",
      "ec2:CreateSecurityGroup",
      "ec2:DeleteSecurityGroup",
      "ec2:AuthorizeSecurityGroupEgress",
      "ec2:AuthorizeSecurityGroupIngress",
      "ec2:RevokeSecurityGroupEgress",
      "ec2:RevokeSecurityGroupIngress",
      "ec2:CreateVolume",
      "ec2:DeleteVolume",
      "ec2:AttachVolume",
      "ec2:DetachVolume",
    ]

    resources = ["*"]
  }

  statement {
    sid    = "Storage"
    effect = "Allow"

    actions = ["s3:*"]

    resources = [
      "arn:${data.aws_partition.current.partition}:s3:::${var.project}-${var.environment}-*",
      "arn:${data.aws_partition.current.partition}:s3:::${var.project}-${var.environment}-*/*",
    ]
  }

  statement {
    sid    = "Keys"
    effect = "Allow"

    actions = [
      "kms:CreateKey",
      "kms:CreateAlias",
      "kms:DeleteAlias",
      "kms:ScheduleKeyDeletion",
      "kms:CancelKeyDeletion",
      "kms:EnableKeyRotation",
      "kms:DisableKeyRotation",
      "kms:PutKeyPolicy",
      "kms:TagResource",
      "kms:UntagResource",
    ]

    resources = ["*"]
  }

  statement {
    sid    = "ProjectScopedIAM"
    effect = "Allow"

    actions = [
      "iam:CreateRole",
      "iam:DeleteRole",
      "iam:UpdateRole",
      "iam:PutRolePolicy",
      "iam:DeleteRolePolicy",
      "iam:AttachRolePolicy",
      "iam:DetachRolePolicy",
      "iam:CreateInstanceProfile",
      "iam:DeleteInstanceProfile",
      "iam:AddRoleToInstanceProfile",
      "iam:RemoveRoleFromInstanceProfile",
      "iam:TagRole",
      "iam:UntagRole",
      "iam:TagInstanceProfile",
      "iam:UntagInstanceProfile",
    ]

    resources = [
      "arn:${data.aws_partition.current.partition}:iam::${var.account_id}:role/${var.project}-${var.environment}-*",
      "arn:${data.aws_partition.current.partition}:iam::${var.account_id}:instance-profile/${var.project}-${var.environment}-*",
    ]
  }

  statement {
    sid       = "PassInstanceRole"
    effect    = "Allow"
    actions   = ["iam:PassRole"]
    resources = ["arn:${data.aws_partition.current.partition}:iam::${var.account_id}:role/${var.project}-${var.environment}-*"]

    condition {
      test     = "StringEquals"
      variable = "iam:PassedToService"
      values   = ["ec2.amazonaws.com"]
    }
  }

  # The pipeline's own controls are out of reach of the pipeline.
  statement {
    sid    = "ProtectBootstrap"
    effect = "Deny"

    actions = [
      "iam:*OpenIDConnectProvider*",
      "iam:*Role*",
      "iam:*Policy*",
    ]

    resources = [
      aws_iam_role.terraform_plan.arn,
      aws_iam_role.terraform_apply.arn,
      local.oidc_provider_arn,
    ]
  }
}

resource "aws_iam_role_policy" "apply" {
  name   = "terraform-apply"
  role   = aws_iam_role.terraform_apply.id
  policy = data.aws_iam_policy_document.apply.json
}
