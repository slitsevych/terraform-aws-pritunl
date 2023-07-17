data "aws_vpc" "selected" {
  id = var.vpc_id
}

locals {
  whitelist_ip   = ["${var.whitelist_ip}/32"]
  inbound_ports  = [80, 443]
  pritunl_ports  = [var.ovpn_udp_port, var.wireguard_udp_port]
  cidr_all_block = ["0.0.0.0/0"]
}

resource "aws_security_group" "pritunl" {
  name        = "${var.resource_name_prefix}-vpn"
  description = "Allow necessary connections for pritunl vpn"
  vpc_id      = var.vpc_id

  # port 80: for Let's Encrypt validation ; port 443: for PIN auth
  dynamic "ingress" {
    for_each = local.inbound_ports
    content {
      description = "standard port ${ingress.value} access"
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = local.cidr_all_block
    }
  }

  # VPN WAN access
  dynamic "ingress" {
    for_each = local.pritunl_ports
    content {
      description = "pritunl udp port ${ingress.value} access"
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "udp"
      cidr_blocks = local.cidr_all_block
    }
  }

  # ICMP
  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = [data.aws_vpc.selected.cidr_block]
  }

  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = local.cidr_all_block
  }

  tags = merge(
    tomap({ "Name" = "pritunl-vpn" }),
    var.tags
  )
}

resource "aws_security_group_rule" "ssh" {
  count = var.whitelist_ip == "" ? 1 : 0

  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = local.whitelist_ip
  security_group_id = aws_security_group.pritunl.id
}
