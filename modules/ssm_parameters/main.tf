resource "aws_ssm_parameter" "this" {
  for_each = { for param in var.parameters : param.name => param }

  name = each.value.name
  type = lookup(each.value, "type", "String")
  value = lookup(each.value, "value", "change_me")
  description = lookup(each.value, "description", "Managed by Terraform")

  lifecycle {
    ignore_changes = [value]
  }
}
