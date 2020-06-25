data "aws_caller_identity" "current" {}

data "aws_ami" "oracle" {
  most_recent = true

  filter {
    name   = "name"
    values = ["OL8.2-x86_64-HVM-2020-05-22"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["131827586825"] # Oracle
}

resource "aws_instance" "pritunl" {
  ami           = data.aws_ami.oracle.id
  instance_type = var.instance_type
  key_name      = var.aws_key_name
  user_data     = file("${path.module}/provision.sh")

	root_block_device {
    volume_size = var.volume_size
  }

  vpc_security_group_ids = [
    aws_security_group.pritunl.id,
    aws_security_group.allow_from_office.id,
  ]

  subnet_id                   = var.public_subnet_id
  associate_public_ip_address = true  
  tags = merge( map("Name", format("%s-%s", var.resource_name_prefix, "vpn")), var.tags,)
}

resource "aws_eip" "pritunl" {
  instance = aws_instance.pritunl.id
  vpc      = true
}
