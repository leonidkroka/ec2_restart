variable "gitlab_project_path" {
  type = string
  description = "GitLab address (group/repository or username/repository)"
  default = "630353335020/internal-projects/630353335020-sdo/infra-actions"
}

variable "gitlab_branch" {
  type = string
  description = "Allowed branch"
  default = "master"
}
