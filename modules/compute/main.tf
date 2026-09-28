data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-kernel-6.1-x86_64"]
  }
}

# No SSH key: access is via SSM Session Manager, which needs no inbound rules.
data "aws_iam_policy_document" "assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "this" {
  name               = "${var.name}-instance"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
  tags               = var.tags
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.this.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Exactly one bucket and one key.
data "aws_iam_policy_document" "bucket_access" {
  statement {
    effect    = "Allow"
    actions   = ["s3:ListBucket", "s3:GetBucketLocation"]
    resources = [var.bucket_arn]
  }

  statement {
    effect = "Allow"

    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
    ]

    resources = ["${var.bucket_arn}/*"]
  }

  statement {
    effect = "Allow"

    actions = [
      "kms:Decrypt",
      "kms:GenerateDataKey",
    ]

    resources = [var.bucket_kms_key_arn]
  }
}

resource "aws_iam_role_policy" "bucket_access" {
  name   = "${var.name}-bucket-access"
  role   = aws_iam_role.this.id
  policy = data.aws_iam_policy_document.bucket_access.json
}

resource "aws_iam_instance_profile" "this" {
  name = "${var.name}-instance"
  role = aws_iam_role.this.name
}

resource "aws_security_group" "this" {
  name_prefix = "${var.name}-sg-"
  description = "Egress-only security group for ${var.name}"
  vpc_id      = var.vpc_id
  tags        = var.tags

  # No ingress rules by design - SSM initiates outbound connections.

  # A security group cannot be deleted while an instance still references it,
  # so any change forcing replacement deadlocks without this. name_prefix
  # keeps the two from colliding on name during the swap.
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_egress_rule" "https" {
  security_group_id = aws_security_group.this.id
  description       = "HTTPS egress for SSM, package repos and S3"
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
}

resource "aws_instance" "this" {
  ami                    = data.aws_ami.al2023.id
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [aws_security_group.this.id]
  iam_instance_profile   = aws_iam_instance_profile.this.name

  associate_public_ip_address = var.assign_public_ip
  monitoring                  = var.environment == "prod"

  # IMDSv2 only - blocks the SSRF-to-credential-theft path.
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  root_block_device {
    volume_type           = "gp3"
    volume_size           = var.root_volume_size
    encrypted             = true
    delete_on_termination = true
  }

  tags = merge(var.tags, { Name = var.name })

  lifecycle {
    # A new AMI release must not silently queue an instance replacement.
    ignore_changes = [ami]
  }

}
