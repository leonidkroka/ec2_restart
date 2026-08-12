variable "aws_region" {
  type = string
  description = "AWS Lambda region"
  default = "eu-central-1"
}

variable "aws_ssm_region" {
  type = string
  description = "AWS SSM region"
  default = "eu-central-1"
}

variable "cloudflare_zone_id_path" {
  type = string
  description = "AWS Parameters Store path for CF zone ID"
  default = "/backend/cloudflare_cache_purge/zone_id"
}

variable "cloudflare_secondary_zone_id_path" {
  type = string
  description = "AWS Parameters Store path for Design CF zone ID"
  default = "/backend/cloudflare_cache_purge/secondary_zone_id"
}

variable "cloudflare_api_token_path" {
  type = string
  description = "AWS Parameters Store path for CF API token"
  default = "/backend/cloudflare_cache_purge/cloudflare/api/token"
}

variable "slack_signing_secret_path" {
  type = string
  description = "AWS Parameters Store path for Slack secret(HMAC authorization)"
  default = "/backend/cloudflare_cache_purge/slack_signing_secret"
}

variable "slack_channel_id_path" {
  type = string
  description = "AWS Parameters Store path for Slack channel ID, from which EC2 restart is allowed"
  default = "/backend/cloudflare_cache_purge/slack_channel_id"
}

variable "parameters" {
  type = list(any)
  description = "List of SSM parameters to create"
  default = [
    {
      name = "/backend/cloudflare_cache_purge/zone_id"
      value = "change_me"
      description = "Target zone ID"
    },
    {
      name = "/backend/cloudflare_cache_purge/secondary_zone_id"
      value = "change_me"
      description = "Target zone ID"
    },
    {
      name = "/backend/cloudflare_cache_purge/cloudflare/api/token"
      value = "change_me"
      description = "CloudFlare API token"
    },
    {
      name = "/backend/cloudflare_cache_purge/slack_channel_id"
      value = "change_me"
      description = "Slack Channel ID authorized for triggering reboot"
    },
    {
      name = "/backend/cloudflare_cache_purge/slack_signing_secret"
      value = "change_me"
      type = "SecureString"
      description = "Slack Signing Secret for HMAC authorization"
    }
  ]
}
