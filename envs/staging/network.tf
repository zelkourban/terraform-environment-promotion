# The default VPC is used deliberately.
#
# Building a VPC is not what this exercise is about, and a purpose-built
# private-subnet VPC needs either a NAT gateway (~$32/mo) or three SSM
# interface endpoints (~$22/mo) before an instance can reach Systems Manager
# at all. Multiplied across three environments that is ~$100/mo to run one
# t3.micro. A real deployment would consume a shared network module here and
# pass private subnet IDs in.

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}
