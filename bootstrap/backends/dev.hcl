# bucket is passed at init: -backend-config="bucket=acme-tfstate-dev-$AWS_ACCOUNT_ID"
key          = "bootstrap/terraform.tfstate"
region       = "eu-central-1"
encrypt      = true
use_lockfile = true
