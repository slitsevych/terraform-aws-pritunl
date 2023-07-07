data "aws_iam_policy_document" "assume_role" {
  count = length(var.iam_instance_profile) > 0 ? 0 : 1 

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
  count = length(var.iam_instance_profile) > 0 ? 0 : 1 

  name               = "${var.resource_name_prefix}-ec2-ssm-role"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.assume_role[0].json
}

resource "aws_iam_role_policy_attachment" "ssm_policy_attach" {
  count = length(var.iam_instance_profile) > 0 ? 0 : 1 

  role       = aws_iam_role.ec2_ssm_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"

  depends_on = [aws_iam_role.ec2_ssm_role]
}

resource "aws_iam_instance_profile" "ssm_profile" {
  count = length(var.iam_instance_profile) > 0 ? 0 : 1 
  
  name = "${var.resource_name_prefix}-ec2-ssm-role"
  role = aws_iam_role.ec2_ssm_role[0].name

  depends_on = [aws_iam_role.ec2_ssm_role]
}