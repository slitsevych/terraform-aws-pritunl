output "pritunl_private_ip" {
  value = aws_instance.pritunl.private_ip
}

output "pritunl_public_ip" {
  value = aws_eip.pritunl.public_ip
}

output "main_security_group_id" {
  value = aws_security_group.pritunl.id
}

output "aws_instance_id" {
  value = aws_instance.pritunl.id
}

output "pritunl_dns_alias" {
  value = one(aws_route53_record.vpn[*].fqdn)
}

