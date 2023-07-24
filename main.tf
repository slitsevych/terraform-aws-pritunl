data "aws_ami" "oracle" {
  most_recent = true

  filter {
    name   = "name"
    values = ["OL8.7-x86_64-HVM-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["131827586825"] # Oracle
}

resource "aws_instance" "pritunl" {
  ami                  = var.platform == "amd64" ? data.aws_ami.oracle.id : var.custom_ami_id
  instance_type        = var.instance_type
  source_dest_check    = false
  key_name             = var.aws_key_name != "" ? var.aws_key_name : null
  user_data            = var.platform == "amd64" ? file("${path.module}/scripts/provision_amd64.sh") : file("${path.module}/scripts/provision_arm64.sh")
  iam_instance_profile = var.aws_iam_instance_profile == "" ? aws_iam_instance_profile.ssm_profile[0].name : var.aws_iam_instance_profile

  root_block_device {
    volume_size           = var.volume_size
    volume_type           = "gp3"
    tags                  = merge(tomap({ "Name" = format("%s-%s", var.resource_name_prefix, "vpn") }), var.tags)
    delete_on_termination = false
  }

  vpc_security_group_ids = compact(flatten([
    aws_security_group.pritunl.id,
    var.additional_security_group
  ]))

  subnet_id                   = var.public_subnet_id
  associate_public_ip_address = true

  tags = merge(tomap({ "Name" = format("%s-%s", var.resource_name_prefix, "vpn") }), var.tags)

  lifecycle {
    ignore_changes = [user_data, ami]
  }
}

resource "aws_eip" "pritunl" {
  domain   = "vpc"
  instance = aws_instance.pritunl.id
  tags     = merge(tomap({ "Name" = format("%s-%s", var.resource_name_prefix, "vpn") }), var.tags)
}
