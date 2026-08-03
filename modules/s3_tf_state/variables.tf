variable "bucket_name" {
  type = string
  description = "Name of the S3 bucket for Terraform state"
  default = "630353335020-infrastructure-tf-state"
}

variable "dynamodb_table_name" {
  type = string
  description = "Name of the DynamoDB table for state locking"
  default = "infrastructure-tf-locks"
}

variable "noncurrent_version_retention_days" {
  type = number
  description = "Days to retain old versions of tfstate"
  default = 30
}
