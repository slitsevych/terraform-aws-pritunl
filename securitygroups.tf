data "aws_vpc" "selected" {
  id = var.vpc_id
}

resource "aws_security_group" "pritunl" {
  name        = "${var.resource_name_prefix}-vpn"
  description = "Allow necessary connections for pritunl vpn"
  vpc_id      = var.vpc_id

  # SSH access
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${var.designated_ip}/32"]
  }

  # For Let's Encrypt validation
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTPS access is required for PIN auth
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # VPN WAN access
  ingress {
    from_port   = var.udp_port
    to_port     = var.udp_port
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # ICMP
  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = length(var.internal_cidrs) == 0 ? [data.aws_vpc.selected.cidr_block] : var.internal_cidrs
  }

  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    tomap({ "Name" = "pritunl-vpn" }),
    var.tags,
  )
}
