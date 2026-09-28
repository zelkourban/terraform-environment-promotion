project     = "acme"
environment = "prod"
region      = "eu-central-1"

# account_id comes from TF_VAR_account_id - see README.

instance_type    = "t3.small"
root_volume_size = 50

# Prod keeps the public-IP shortcut off. Running this environment for real
# means supplying a private subnet with NAT or SSM interface endpoints.
assign_public_ip = false

noncurrent_version_expiration_days = 365
