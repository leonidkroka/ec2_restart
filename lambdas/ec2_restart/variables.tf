variable "aws_region_path" {
  type = string
  description = "AWS EC2 region for deployment"
  default = "/backend/general/region"
}

variable "ec2_instance_id_path" {
  type = string
  description = "AWS Parameters Store path for EC2 instance ID"
  default = "/backend/ec2_restart/instance_id"
}

variable "slack_signing_secret_path" {
  type = string
  description = "AWS Parameters Store path for Slack secret(HMAC authorization)"
  default = "/backend/ec2_restart/slack_signing_secret"
}

variable "slack_channel_id_path" {
  type = string
  description = "AWS Parameters Store path for Slack channel ID, from which EC2 restart is allowed"
  default = "/backend/ec2_restart/slack_channel_id"
}

variable "aws_region" {
  type = string
  description = "AWS Lambda region"
  default = "eu-west-1"
}

variable "aws_ssm_region" {
  type = string
  description = "AWS SSM region"
  default = "eu-west-1"
}
