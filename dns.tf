data "aws_route53_zone" "public_zone" {
  name = var.domain_name
}

resource "aws_route53_record" "vpn" {
  zone_id = data.aws_route53_zone.public_zone.zone_id
  name    = "${var.resource_name_prefix}.${data.aws_route53_zone.public_zone.name}"
  type    = "A"
  ttl     = 300
  records = [aws_instance.pritunl.public_ip]
}