terraform {
  # Partial backend configuration: the bucket name embeds the AWS account ID,
  # which is deliberately not committed. It is supplied at init time:
  #
  #   terraform init -backend-config="bucket=acme-tfstate-dev-$AWS_ACCOUNT_ID"
  #
  # State lives in the same account as the resources it describes, so a
  # compromised lower-environment pipeline cannot reach another's state.
  backend "s3" {
    key          = "env/dev/terraform.tfstate"
    region       = "eu-central-1"
    encrypt      = true
    use_lockfile = true
  }
}
