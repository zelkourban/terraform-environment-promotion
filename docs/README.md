# Diagrams

Rendered with [awslabs/diagram-as-code](https://github.com/awslabs/diagram-as-code)
from the YAML sources in this directory, so the pictures change through pull
requests like the rest of the repository.

```bash
awsdac docs/architecture.yaml -o docs/architecture.png -f
awsdac docs/pipeline.yaml     -o docs/pipeline.png     -f
```

## `architecture.png`

What exists in AWS: three accounts under one Organization, each holding its own
state bucket, its own pair of Terraform roles, and one copy of the application
stack. Nothing is shared across the account boundary.

Note prod's private subnet against dev and staging's public ones - that is the
`assign_public_ip` trade-off described in the root README, not an oversight.

The gp3 volume beside each instance is the encrypted root volume the `compute`
module creates.

## `pipeline.png`

How a change moves. The top lane is a pull request: checks, then a plan against
all three environments using read-only roles. The bottom lane is the merge:
dev applies automatically, staging and prod each wait on a required reviewer.

