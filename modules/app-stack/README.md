# `app-stack`

Composition module: one `secure-bucket` + one `compute` instance, wired
together so the instance can reach exactly that bucket.

This is the module the environment roots consume. Keeping the composition here
rather than in `envs/*/main.tf` means adding a resource to the stack is a
single-file change that lands in all three environments through the normal
promotion flow, instead of three near-identical copy-pastes.

## Environment-dependent behaviour

| Input | dev / staging | prod |
|---|---|---|
| `force_destroy` on the bucket | `true` | `false` (also enforced inside `secure-bucket`) |
| detailed CloudWatch monitoring | off | on |
| KMS deletion window | 7 days | 30 days |

Everything else is driven by `envs/<env>/terraform.tfvars`.

## Usage

```hcl
module "app_stack" {
  source = "../../modules/app-stack"

  project       = "acme"
  environment   = "dev"
  vpc_id        = data.aws_vpc.default.id
  subnet_id     = sort(data.aws_subnets.default.ids)[0]
  instance_type = "t3.micro"

  # Low-cost path for non-production: reachable SSM agent without NAT.
  assign_public_ip   = true
  smoke_test_on_boot = true
}
```
