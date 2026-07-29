terraform {
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
}

provider "aws" {
  region = "eu-west-1"
}

data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/src"
  output_path = "${path.module}/lambda_function.zip"
}

resource "aws_iam_role" "lambda_role" {
  name = "ec2_restart_lambda_execution_role"

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
  name = "ec2_reboot_inline"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = ["ec2:RebootInstances", "ec2:DescribeInstances"]
        Resource = "*"
      }
    ]
  })
}

resource "aws_lambda_function" "ec2_restart_lambda" {
  filename = data.archive_file.lambda_zip.output_path
  function_name = "restart_ec2_lambda"
  role = aws_iam_role.lambda_role.arn
  runtime = "ruby3.2"
  handler = "lambda_function.lambda_handler"
  memory_size = 1024
  timeout = 20

  environment {
    variables = {
      TARGET_INSTANCE_ID = "i-014a14322c6XXXX" # ID EC2
      SLACK_SIGNING_SECRET = "XXXXXX"
      EC2_REGION = "eu-west-1"
      SLACK_CHANNEL_ID = "C01R2UXXXX"
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
