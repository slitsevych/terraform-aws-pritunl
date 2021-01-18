resource "aws_security_group" "pritunl" {
  name        = "${var.resource_name_prefix}-vpn"
  description = "${var.resource_name_prefix}-vpn"
  vpc_id      = var.vpc_id

  # SSH access
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.internal_cidrs
  }

	# For Let's Encrypt validation
	ingress {
    from_port = 80
    to_port   = 80
    protocol  = "tcp"
    cidr_blocks = var.whitelist_http
  }

  # HTTPS access
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.internal_cidrs
  }

  # VPN WAN access
  ingress {
    from_port   = 10000
    to_port     = 19999
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # ICMP
  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = var.internal_cidrs
  }

  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    map("Name", format("%s-%s", var.resource_name_prefix, "vpn")),
    var.tags,
  )
}

resource "aws_security_group" "allow_from_office" {
  name        = "${var.resource_name_prefix}-whitelist"
  description = "Allows SSH connections and HTTP(s) connections from office"
  vpc_id      = var.vpc_id

  # SSH access
  ingress {
    description = "Allow SSH access from select CIDRs"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.whitelist
  }

  # HTTPS access
  ingress {
    description = "Allow HTTPS access from select CIDRs"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.whitelist
  }

  # ICMP
  ingress {
    description = "Allow ICMPv4 from select CIDRs"
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = var.whitelist
  }

  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    map("Name", format("%s-%s", var.resource_name_prefix, "whitelist")),
    var.tags,
  )
}
