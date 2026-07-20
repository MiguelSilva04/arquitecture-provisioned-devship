data "aws_iam_policy_document" "ec2_trust" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "platform" {
  name               = "devship-platform-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_trust.json
}

data "aws_iam_policy_document" "assume_client_roles" {
  statement {
    actions   = ["sts:AssumeRole"]
    resources = ["arn:aws:iam::*:role/${var.client_role_prefix}*"]
  }
}

resource "aws_iam_role_policy" "assume_client_roles" {
  name   = "devship-assume-client-roles"
  role   = aws_iam_role.platform.id
  policy = data.aws_iam_policy_document.assume_client_roles.json
}

resource "aws_iam_instance_profile" "platform" {
  name = "devship-platform-instance-profile"
  role = aws_iam_role.platform.name
}
