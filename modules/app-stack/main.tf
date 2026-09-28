data "aws_caller_identity" "current" {}

locals {
  name_prefix = "${var.project}-${var.environment}"

  # Globally unique across all of AWS; the account ID is deterministic, unlike
  # a random_id that would live in state.
  bucket_name = "${local.name_prefix}-${var.bucket_suffix}-${data.aws_caller_identity.current.account_id}"

  tags = merge(
    {
      Project     = var.project
      Environment = var.environment
      ManagedBy   = "terraform"
    },
    var.tags,
  )
}

module "bucket" {
  source = "../secure-bucket"

  name        = local.bucket_name
  environment = var.environment

  versioning_enabled                 = true
  noncurrent_version_expiration_days = var.noncurrent_version_expiration_days
  access_log_bucket                  = var.access_log_bucket

  # Non-prod is disposable; secure-bucket hard-overrides this for prod anyway.
  force_destroy = var.environment != "prod"

  tags = local.tags
}

module "compute" {
  source = "../compute"

  name        = "${local.name_prefix}-app"
  environment = var.environment

  instance_type    = var.instance_type
  root_volume_size = var.root_volume_size
  vpc_id           = var.vpc_id
  subnet_id        = var.subnet_id
  assign_public_ip = var.assign_public_ip

  bucket_arn         = module.bucket.bucket_arn
  bucket_kms_key_arn = module.bucket.kms_key_arn

  tags = local.tags
}
