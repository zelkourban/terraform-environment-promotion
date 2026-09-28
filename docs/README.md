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

## `pipeline.png`

How a change moves. The top lane is a pull request: checks, then a plan against
all three environments using read-only roles. The bottom lane is the merge:
dev applies automatically, staging and prod each wait on a required reviewer.

## Layout notes

`awsdac` does not measure label width when sizing anything. Leaf resources lay
out on a fixed margin, so long titles overrun their neighbours; group boxes are
sized to their children, so a group whose label is wider than its contents
spills past its own border. Both are fixed by shortening the title - hence
`public` rather than the preset's `Public Subnet`, over a box holding one icon.
Put the detail here instead.

Group containers carry their own icon - `AWS::Diagram::Cloud` stamps an AWS
logo on anything it wraps, which is wrong for a lane spanning GitHub and AWS.
The pipeline diagram uses bare `HorizontalStack`/`VerticalStack` containers for
that reason.
