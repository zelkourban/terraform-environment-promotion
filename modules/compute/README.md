# `compute`

A single EC2 instance with no inbound access and a tightly scoped identity.

## Contract

- No SSH key and no ingress rules at all. Access via SSM Session Manager.
- No public IP unless `assign_public_ip` is set, which makes the SSM agent
  reachable without NAT. Ingress stays empty either way.
- IMDSv2 required, hop limit 1.
- Encrypted gp3 root volume.
- An instance role granting S3 read/write on **one** bucket ARN and
  `kms:Decrypt`/`GenerateDataKey` on **one** key ARN - nothing else.
- `ignore_changes = [ami]` so an upstream AMI release does not silently queue
  an instance replacement.

## Usage

```hcl
module "app" {
  source = "../../modules/compute"

  name               = "acme-dev-app"
  environment        = "dev"
  vpc_id             = data.aws_vpc.this.id
  subnet_id          = data.aws_subnets.private.ids[0]
  bucket_arn         = module.data.bucket_arn
  bucket_kms_key_arn = module.data.kms_key_arn
  tags               = local.tags
}
```
