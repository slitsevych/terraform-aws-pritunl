data "aws_route53_zone" "public_zone" {
  name = var.domain_name
}

data "aws_route53_zone" "private_zone" {
  name         = var.domain_name
  private_zone = true
}

resource "aws_route53_record" "vpn" {
  zone_id = data.aws_route53_zone.public_zone.zone_id
  name    = "${var.subdomain_prefix}.${data.aws_route53_zone.public_zone.name}"
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
  zone_id = data.aws_route53_zone.private_zone.zone_id
  name    = "${var.subdomain_prefix}.${data.aws_route53_zone.private_zone.name}"
  type    = "A"
  ttl     = 300
  records = [aws_eip.pritunl.private_ip]

  lifecycle {
    ignore_changes = [
      zone_id
    ]
  }
}