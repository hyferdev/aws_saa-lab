# Sprint 3 network probe — validates SSM reachability into a private subnet.
# Remove this file in sprint 4 when the ASG replaces it.

data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_security_group" "ssm_probe" {
  name        = "${local.shared_prefix}-ssm-probe"
  description = "No inbound. Outbound HTTPS only for SSM."
  vpc_id      = module.network.vpc_id

  tags = merge(local.tags, { Name = "${local.shared_prefix}-ssm-probe" })
}

resource "aws_vpc_security_group_egress_rule" "ssm_probe_https" {
  security_group_id = aws_security_group.ssm_probe.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
  description       = "HTTPS to SSM service endpoints via NAT."
}

resource "aws_instance" "ssm_probe" {
  ami                    = data.aws_ami.al2023.id
  instance_type          = "t3.micro"
  subnet_id              = module.network.private_subnet_map["a"]
  iam_instance_profile   = module.frontdesk.instance_profile_name
  vpc_security_group_ids = [aws_security_group.ssm_probe.id]

  metadata_options {
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  root_block_device {
    encrypted = true
  }

  tags = merge(local.tags, { Name = "${local.shared_prefix}-ssm-probe" })
}
