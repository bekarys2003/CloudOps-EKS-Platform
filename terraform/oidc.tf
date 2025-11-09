resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
}

data "aws_iam_policy_document" "gha_trust" {
  statement {
    effect = "Allow"
    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }
    actions = ["sts:AssumeRoleWithWebIdentity"]
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }
    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:${var.github_org}/${var.github_repo}:ref:refs/heads/${var.branch}"]
    }
  }
}

resource "aws_iam_role" "gha_build_push" {
  name               = "gha-ecr-build-push"
  assume_role_policy = data.aws_iam_policy_document.gha_trust.json
}

resource "aws_iam_policy" "ecr_push" {
  name   = "ECRPushForOnlineBoutique"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      { Effect="Allow", Action=["ecr:GetAuthorizationToken"], Resource="*" },
      { Effect="Allow", Action=[
          "ecr:BatchCheckLayerAvailability","ecr:CompleteLayerUpload",
          "ecr:UploadLayerPart","ecr:InitiateLayerUpload","ecr:PutImage",
          "ecr:BatchGetImage","ecr:DescribeRepositories","ecr:CreateRepository"
        ], Resource="*" }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_ecr_push" {
  role       = aws_iam_role.gha_build_push.name
  policy_arn = aws_iam_policy.ecr_push.arn
}

output "gha_build_push_role_arn" { value = aws_iam_role.gha_build_push.arn }
