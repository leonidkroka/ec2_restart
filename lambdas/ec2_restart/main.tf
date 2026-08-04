terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.0"
    }
  }

  backend "s3" {
    bucket = "leobit-infrastructure-tf-state"
    key = "environments/prod/ec2_restart/terraform.tfstate"
    region = "eu-west-1"
    dynamodb_table = "infrastructure-tf-locks"
    encrypt = true
  }
}

provider "aws" {
  region = var.aws_region
}

data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/src"
  output_path = "${path.module}/lambda_function.zip"
}

data "aws_caller_identity" "current" {}

resource "aws_iam_role" "lambda_role" {
  name = "backend-ec2-restart-lambda-execution-role"
  permissions_boundary = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:policy/LambdaPermissionsBoundary"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "lambda_ec2_inline" {
  name = "backend-ec2-reboot-inline"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
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
        Resource = "arn:aws:ssm:*:*:parameter/backend/*"
      }
    ]
  })
}

resource "aws_lambda_function" "ec2_restart_lambda" {
  filename = data.archive_file.lambda_zip.output_path
  function_name = "backend-restart-ec2-lambda"
  role = aws_iam_role.lambda_role.arn
  runtime = "ruby3.4"
  handler = "lambda_function.lambda_handler"
  memory_size = 1024
  timeout = 20

  environment {
    variables = {
      EC2_REGION_PATH = var.aws_region_path
      TARGET_INSTANCE_ID_PATH = var.ec2_instance_id_path
      SLACK_SIGNING_SECRET_PATH = var.slack_signing_secret_path
      SLACK_CHANNEL_ID_PATH = var.slack_channel_id_path
      SSM_REGION = var.aws_ssm_region
    }
  }

  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  depends_on = [aws_iam_role_policy_attachment.lambda_logs]
}

resource "aws_lambda_function_url" "ec2_restart_url" {
  function_name = aws_lambda_function.ec2_restart_lambda.function_name
  authorization_type = "NONE"
}

resource "aws_lambda_permission" "allow_public_url" {
  statement_id = "FunctionURLAllowPublicAccess"
  action = "lambda:InvokeFunctionUrl"
  function_name = aws_lambda_function.ec2_restart_lambda.function_name
  principal = "*"
  function_url_auth_type = "NONE"
}

output "lambda_function_url" {
  value = aws_lambda_function_url.ec2_restart_url.function_url
  description = "Insert this URL into Slack Slash Command Request URL"
}
