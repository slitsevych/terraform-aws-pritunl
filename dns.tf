data "aws_route53_zone" "public_zone" {
  count = var.public_domain_name == "" ? 0 : 1

  name = var.public_domain_name
}

data "aws_route53_zone" "private_zone" {
  count = var.private_domain_name == "" ? 0 : 1

  name         = var.private_domain_name
  private_zone = true
}

resource "aws_route53_record" "vpn" {
  count = var.public_domain_name == "" ? 0 : 1

  zone_id = data.aws_route53_zone.public_zone[0].zone_id
  name    = "${var.resource_name_prefix}.${data.aws_route53_zone.public_zone[0].name}"
  type    = "A"
  ttl     = 300
  records = [aws_eip.pritunl.public_ip]

  lifecycle {
    ignore_changes = [
      zone_id
    ]
  }
}

resource "aws_route53_record" "vpn_private" {
  count = var.private_domain_name == "" ? 0 : 1

  zone_id = data.aws_route53_zone.private_zone[0].zone_id
  name    = "${var.resource_name_prefix}.${data.aws_route53_zone.private_zone[0].name}"
  type    = "A"
  ttl     = 300
  records = [aws_eip.pritunl.private_ip]

  lifecycle {
    ignore_changes = [
      zone_id
    ]
  }
}