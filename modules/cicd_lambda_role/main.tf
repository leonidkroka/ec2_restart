resource "aws_iam_openid_connect_provider" "gitlab" {
  url             = "https://gitlab.com"
  client_id_list  = ["https://gitlab.com"]
  thumbprint_list = ["b3ed444352414217054dd8065d64c494384f4992"]
}

resource "aws_iam_role" "gitlab_ci_role" {
  name = "gitlab-ci-lambda-deployer"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.gitlab.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "gitlab.com:sub" = "project_path:${var.gitlab_project_path}:ref_type:branch:ref:${var.gitlab_branch}"
          }
        }
      }
    ]
  })
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

resource "aws_iam_role_policy" "gitlab_ci_policy" {
  name = "gitlab-ci-lambda-update-policy"
  role = aws_iam_role.gitlab_ci_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "lambda:UpdateFunctionCode",
          "lambda:UpdateFunctionConfiguration",
          "lambda:GetFunction",
          "lambda:ListFunctions"
        ]
        Resource = "arn:aws:lambda:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:function:*"
      }
    ]
  })
}

output "gitlab_ci_role_arn" {
  value = aws_iam_role.gitlab_ci_role.arn
}
