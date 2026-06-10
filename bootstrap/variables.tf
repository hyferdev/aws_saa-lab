variable "region" {
  description = "Home region for the sprint."
  type        = string
  default     = "us-east-1"
}

variable "project" {
  description = "Name prefix for all resources."
  type        = string
  default     = "saa-sprint"
}

variable "github_org" {
  description = "Your GitHub username or org (the part before the slash in org/repo)."
  type        = string
}

variable "github_repo" {
  description = "The repo name you just created (the part after the slash)."
  type        = string
}
