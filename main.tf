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
  key_name             = var.aws_key_name
  user_data            = var.platform == "amd64" ? file("${path.module}/scripts/provision_amd64.sh") : file("${path.module}/scripts/provision_arm64.sh")
  iam_instance_profile = length(var.iam_instance_profile) > 0 ? var.iam_instance_profile : aws_iam_instance_profile.ssm_profile.name

  root_block_device {
    volume_size           = var.volume_size
    tags                  = merge(tomap({ "Name" = format("%s-%s", var.resource_name_prefix, "vpn") }), var.tags, )
    delete_on_termination = false
  }

  lifecycle {
    ignore_changes = [user_data, ami]
  }

  vpc_security_group_ids = compact(flatten([
    aws_security_group.pritunl.id,
    var.additional_security_group
  ]))

  subnet_id                   = var.public_subnet_id
  associate_public_ip_address = true
  tags                        = merge(tomap({ "Name" = format("%s-%s", var.resource_name_prefix, "vpn") }), var.tags, )
}

resource "aws_eip" "pritunl" {
  instance = aws_instance.pritunl.id
  tags     = merge(tomap({ "Name" = format("%s-%s", var.resource_name_prefix, "vpn") }), var.tags, )
}
