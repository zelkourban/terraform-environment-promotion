terraform {
  # Partial: the bucket name embeds the account ID and is passed at init.
  backend "s3" {
    key          = "env/dev/terraform.tfstate"
    region       = "eu-central-1"
    encrypt      = true
    use_lockfile = true
  }
}
