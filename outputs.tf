output "pritunl_private_ip" {
  value = aws_instance.pritunl.private_ip
}

output "pritunl_public_ip" {
  value = aws_eip.pritunl.public_ip
}

output "security_group_ids" {
  value = [aws_security_group.pritunl.id]
}

output "main_security_group_id" {
  value = aws_security_group.pritunl.id
}

output "aws_instance_id" {
  value = aws_instance.pritunl.id
}

output "aws_ami_id" {
  value = data.aws_ami.oracle.id
}

output "arn" {
  value = aws_instance.pritunl.arn
}

output "dns_record" {
  value = aws_route53_record.vpn.fqdn
}

