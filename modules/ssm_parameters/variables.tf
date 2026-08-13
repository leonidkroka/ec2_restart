variable "parameters" {
  type = list(any)
  description = "List of SSM parameters to create"
  default = []
}