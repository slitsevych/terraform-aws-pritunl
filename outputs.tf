output "pritunl_private_ip" {
  value = aws_instance.pritunl.private_ip
}

output "pritunl_elastic_ip" {
  value = aws_eip.pritunl.public_ip
}

output "security_group_ids" {
  value = ["${aws_security_group.pritunl.id}",  "${aws_security_group.allow_from_office.id}"]
}

output "main_security_group_id" {
  value = "${aws_security_group.pritunl.id}"
}

output "office_security_group_id" {
  value = "${aws_security_group.allow_from_office.id}"
}

output "aws_instance_id" {
  value = "${aws_instance.pritunl.id}"
}

output "aws_ami_id" {
  value = "${data.aws_ami.oracle.id}"
}
