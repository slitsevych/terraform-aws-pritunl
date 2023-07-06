data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "ec2_ssm_role" {
  count              = var.create_iam_role == true ? 1 : 0
  name               = "${resource_name_prefix}-ec2-ssm-role"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_role_policy_attachment" "ssm_policy_attach" {
  role       = aws_iam_role.ec2_ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"

  depends_on = [aws_iam_role.ec2_ssm_role]
}

resource "aws_iam_instance_profile" "ssm_profile" {
  name = "ec2-ssm-role"
  role = aws_iam_role.ec2_ssm_role.name

  depends_on = [aws_iam_role.ec2_ssm_role]
}