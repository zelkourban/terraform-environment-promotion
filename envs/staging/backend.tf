terraform {
  # State lives in the same account as the resources it describes, so a
  # compromised staging pipeline cannot read or corrupt prod state.
  backend "s3" {
    bucket       = "acme-tfstate-staging-ACCOUNT_ID" # from `terraform -chdir=bootstrap output state_bucket`
    key          = "env/staging/terraform.tfstate"
    region       = "eu-central-1"
    encrypt      = true
    use_lockfile = true
  }
}
