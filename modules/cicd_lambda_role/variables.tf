variable "gitlab_project_path" {
  type        = string
  description = "GitLab address (group/repository or username/repository)"
}

variable "gitlab_branch" {
  type        = string
  description = "Allowed branch"
  default     = "master"
}
