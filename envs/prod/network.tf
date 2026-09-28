# Default VPC by design - a private-subnet build needs NAT or SSM interface
# endpoints before an instance can reach Systems Manager. See README section 7.

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}
