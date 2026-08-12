resource "aws_iam_openid_connect_provider" "gitlab" {
  url = "https://gitlab.com"
  client_id_list = ["https://gitlab.com"]
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

resource "aws_iam_policy" "lambda_boundary" {
  name = "LambdaPermissionsBoundary"
  description = "Max allowed permissions for dynamically created Lambdas"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid = "AllowBasicLambdaExecution"
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = ["ec2:RebootInstances", "ec2:DescribeInstances"]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters"
        ]
        Resource = "arn:aws:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parameter/backend/*"
      }
    ]
  })
}

resource "aws_iam_role_policy" "gitlab_ci_policy" {
  name = "gitlab-ci-lambda-update-policy"
  role = aws_iam_role.gitlab_ci_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid = "ManageLambdasWithPrefix"
        Effect = "Allow"
        Action = [
          "lambda:CreateFunction",
          "lambda:DeleteFunction",
          "lambda:UpdateFunctionCode",
          "lambda:UpdateFunctionConfiguration",
          "lambda:GetFunction",
          "lambda:GetFunctionCodeSigningConfig",
          "lambda:GetPolicy",
          "lambda:ListFunctions",
          "lambda:ListVersionsByFunction",
          "lambda:ListTags",
          "lambda:TagResource",
          "lambda:CreateFunctionUrlConfig",
          "lambda:GetFunctionUrlConfig",
          "lambda:UpdateFunctionUrlConfig",
          "lambda:DeleteFunctionUrlConfig",
          "lambda:AddPermission",
          "lambda:RemovePermission"
        ]
        Resource = "arn:aws:lambda:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:function:backend-*"
      },
      {
        Sid = "ManageRolesWithBoundaryCondition"
        Effect = "Allow"
        Action = [
          "iam:CreateRole",
          "iam:PutRolePolicy",
          "iam:DeleteRolePolicy"
        ]
        Resource = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/backend-*"
        Condition = {
          StringEquals = {
            "iam:PermissionsBoundary" = aws_iam_policy.lambda_boundary.arn
          }
        }
      },
      {
        Sid = "ManageRoleAttachmentsAndInfo"
        Effect = "Allow"
        Action = [
          "iam:GetRole",
          "iam:DeleteRole",
          "iam:UpdateRole",
          "iam:AttachRolePolicy",
          "iam:DetachRolePolicy",
          "iam:GetRolePolicy",
          "iam:ListAttachedRolePolicies",
          "iam:ListRolePolicies",
          "iam:TagRole"
        ]
        Resource = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/backend-*"
      },
      {
        Sid = "ReadAWSManagedPolicies"
        Effect = "Allow"
        Action = [
          "iam:GetPolicy",
          "iam:GetPolicyVersion"
        ]
        Resource = "arn:aws:iam::aws:policy/*"
      },
      {
        Sid    = "PassRoleToLambda"
        Effect = "Allow"
        Action = "iam:PassRole"
        Resource = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/backend-*"
        Condition = {
          StringEquals = {
            "iam:PassedToService" = "lambda.amazonaws.com"
          }
        }
      },
      {
        "Sid": "AllowSSMParameterManagement",
        "Effect": "Allow",
        "Action": [
          "ssm:PutParameter",
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:DeleteParameter",
          "ssm:AddTagsToResource",
          "ssm:ListTagsForResource"
        ],
        "Resource": "arn:aws:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parameter/backend/*"
      },
      {
        "Sid": "AllowSSMDescribe",
        "Effect": "Allow",
        "Action": [
          "ssm:DescribeParameters"
        ],
        "Resource": "*"
      },
      {
        Sid = "ManageCloudWatchLogGroups"
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:DeleteLogGroup",
          "logs:PutRetentionPolicy",
          "logs:DeleteRetentionPolicy",
          "logs:ListTagsForResource",
          "logs:TagResource",
          "logs:UntagResource"
        ]
        Resource = "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/backend-*"
      },
      {
        Sid = "DescribeCloudWatchLogGroups"
        Effect = "Allow"
        Action = [
          "logs:DescribeLogGroups"
        ]
        Resource = "*"
      },
      {
        Sid = "AllowS3BackendBucketLevel"
        Effect = "Allow"
        Action = [
          "s3:ListBucket",
          "s3:GetBucketLocation"
        ]
        Resource = "arn:aws:s3:::630353335020-infrastructure-tf-state"
      },
      {
        Sid = "AllowS3BackendObjectLevel"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = "arn:aws:s3:::630353335020-infrastructure-tf-state/*"
      },
      {
        Sid = "AllowDynamoDBStateLocks"
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:DeleteItem"
        ]
        Resource = "arn:aws:dynamodb:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:table/infrastructure-tf-locks"
      }
    ]
  })
}

output "gitlab_ci_role_arn" {
  value = aws_iam_role.gitlab_ci_role.arn
}
