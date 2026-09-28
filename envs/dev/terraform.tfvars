project     = "acme"
environment = "dev"
region      = "eu-central-1"
account_id  = "FILL_ME" # from `terraform -chdir=bootstrap output account_id`

instance_type    = "t3.micro"
root_volume_size = 20

# Low-cost path: public IP for SSM reachability, still zero ingress rules.
assign_public_ip = true

noncurrent_version_expiration_days = 30
