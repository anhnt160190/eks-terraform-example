locals {
  user_groups = merge([
    for user in yamldecode(file("${path.module}/users.yaml")) :
    {
      for group in user.groups :
      "${user.name}-${group}" => {
        name  = user.name
        group = group
      }
    }
  ]...)
}

resource "aws_iam_group" "eks_admin" {
  name = "EKSAdministrator"
}

resource "aws_iam_group_policy" "eks_admin_policy" {
  name   = "eks_admin_policy"
  group  = aws_iam_group.eks_admin.name
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "sts:AssumeRole",
      "Resource": [
        "${aws_iam_role.eks_admin.arn}"
      ]
    }
  ]
}
EOF
}

resource "aws_iam_group" "eks_developer" {
  name = "EKSDeveloper"
}

resource "aws_iam_group_policy" "eks_developer_policy" {
  name   = "eks_developer_policy"
  group  = aws_iam_group.eks_developer.name
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "sts:AssumeRole",
      "Resource": [
        "${aws_iam_role.eks_developer.arn}"
      ]
    }
  ]
}
EOF
}

resource "aws_iam_group" "kms_group" {
  name = "BuniKMS"
}

resource "aws_iam_group_policy" "kms_policy" {
  name   = "kms_policy"
  group  = aws_iam_group.kms_group.name
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "kms:Decrypt",
        "kms:Encrypt"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_group_membership" "group_memeber" {
  for_each = local.user_groups
  name     = "${each.value.name}-${each.value.group}"
  users = [
    each.value.name
  ]
  group = each.value.group
  depends_on = [
    aws_iam_group.eks_admin,
    aws_iam_group.eks_developer,
    aws_iam_group.kms_group
  ]
}
