output "parameters" {
  value = { for k, v in aws_ssm_parameter.this : k => v.arn }
  description = "Map of parameter names to their ARNs"
}
