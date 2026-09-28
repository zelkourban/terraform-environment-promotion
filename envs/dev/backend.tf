terraform {
  # State lives in the same account as the resources it describes, so a
  # compromised dev pipeline cannot read or corrupt staging/prod state.
  backend "s3" {
    bucket       = "acme-tfstate-dev-ACCOUNT_ID" # from `terraform -chdir=bootstrap output state_bucket`
    key          = "env/dev/terraform.tfstate"
    region       = "eu-central-1"
    encrypt      = true
    use_lockfile = true
  }
}
