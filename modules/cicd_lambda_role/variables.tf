variable "gitlab_project_path" {
  type = string
  description = "GitLab address (group/repository or username/repository)"
  default = "leobit/internal-projects/leobit-sdo/infra-actions"
}

variable "gitlab_branch" {
  type = string
  description = "Allowed branch"
  default = "master"
}
