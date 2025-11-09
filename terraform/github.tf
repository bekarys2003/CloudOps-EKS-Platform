
provider "github" {
  token = var.github_token
  owner = var.github_org
}

data "aws_caller_identity" "me" {}

resource "github_actions_secret" "role_arn" {
  repository    = var.github_repo
  secret_name   = "AWS_GHA_BUILD_PUSH_ROLE_ARN"
  plaintext_value = aws_iam_role.gha_build_push.arn
}

resource "github_actions_secret" "account_id" {
  repository    = var.github_repo
  secret_name   = "AWS_ACCOUNT_ID"
  plaintext_value = data.aws_caller_identity.me.account_id
}
