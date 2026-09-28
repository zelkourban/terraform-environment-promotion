# --------------------------------------------------------------------------
# prod environment root
#
# Thin by design: all logic lives in modules/app-stack. What differs between
# environments is visible in terraform.tfvars, not in this file.
# --------------------------------------------------------------------------

module "app_stack" {
  source = "../../modules/app-stack"

  project     = var.project
  environment = var.environment

  vpc_id    = data.aws_vpc.default.id
  subnet_id = sort(data.aws_subnets.default.ids)[0]

  instance_type    = var.instance_type
  root_volume_size = var.root_volume_size
  assign_public_ip = var.assign_public_ip

  noncurrent_version_expiration_days = var.noncurrent_version_expiration_days
}
