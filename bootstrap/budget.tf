# No budget here on purpose.
#
# Member accounts are created with --iam-user-access-to-billing DENY, so no
# principal inside them can read billing data and CreateBudget is refused:
#
#   AccessDeniedException: Account ... is a linked account. To enable budgets
#   for your account, ask the payer account to enable budgets first.
#
# That setting is worth keeping - workload accounts should not expose billing
# to their own roles. Under consolidated billing every member charge lands on
# the management account anyway, so a single budget there covers all three
# environments and is the correct place for it. See bootstrap/README.md.
