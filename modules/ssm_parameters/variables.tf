variable "parameters" {
  type = list(any)
  description = "List of SSM parameters to create"
  default = [
    {
      name = "/backend/general/region"
      value = "eu-west-1"
      description = "Region where target EC2 instance is located"
    },
    {
      name = "/backend/ec2_restart/instance_id"
      value = "change_me"
      description = "Target EC2 Instance ID to reboot"
    },
    {
      name = "/backend/ec2_restart/slack_channel_id"
      value = "change_me"
      description = "Slack Channel ID authorized for triggering reboot"
    },
    {
      name = "/backend/ec2_restart/slack_signing_secret"
      value = "change_me"
      type = "SecureString"
      description = "Slack Signing Secret for HMAC authorization"
    }
  ]
}
