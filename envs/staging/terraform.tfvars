project     = "acme"
environment = "staging"
region      = "eu-central-1"

# account_id comes from TF_VAR_account_id - see README.

# Staging mirrors prod's shape at a smaller size, so a plan that is clean here
# is a meaningful signal for prod.
instance_type    = "t3.small"
root_volume_size = 30

assign_public_ip = true

noncurrent_version_expiration_days = 60
