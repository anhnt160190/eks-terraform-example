data "aws_iam_policy_document" "eks_policy" {
  statement {
    actions = [
      "eks:DescribeCluster",
      "eks:ListClusters"
    ]
    resources = [
      "*"
    ]
  }
}

data "aws_iam_policy_document" "assume_eks" {
  statement {
    actions = [
      "sts:AssumeRole"
    ]
    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }
    principals {
      type        = "AWS"
      identifiers = [var.accountnum]
    }
  }
}

resource "aws_iam_role" "eks_admin" {
  name               = "EKSAdministrator"
  assume_role_policy = data.aws_iam_policy_document.assume_eks.json
}

resource "aws_iam_role_policy" "eks_admin" {
  name   = "eks_admin"
  role   = aws_iam_role.eks_admin.id
  policy = data.aws_iam_policy_document.eks_policy.json
}

resource "aws_iam_role" "eks_developer" {
  name               = "EKSDeveloper"
  assume_role_policy = data.aws_iam_policy_document.assume_eks.json
}

resource "aws_iam_role_policy" "eks_developer" {
  name   = "eks_developer"
  role   = aws_iam_role.eks_developer.id
  policy = data.aws_iam_policy_document.eks_policy.json
}
