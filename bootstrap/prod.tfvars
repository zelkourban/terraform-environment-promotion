project     = "acme"
environment = "prod"
region      = "eu-central-1"

# account_id comes from TF_VAR_account_id.
github_repository = "zelkourban/terraform-environment-promotion"

# budget_notification_email is passed as TF_VAR_budget_notification_email,
# kept out of the repository so a public mirror does not leak an address.
monthly_budget_usd = 5
