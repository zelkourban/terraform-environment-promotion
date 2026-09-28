terraform {
  # State lives in the same account as the resources it describes, so a
  # compromised lower-environment pipeline cannot reach prod state.
  backend "s3" {
    bucket       = "acme-tfstate-prod-ACCOUNT_ID" # from `terraform -chdir=bootstrap output state_bucket`
    key          = "env/prod/terraform.tfstate"
    region       = "eu-central-1"
    encrypt      = true
    use_lockfile = true
  }
}
