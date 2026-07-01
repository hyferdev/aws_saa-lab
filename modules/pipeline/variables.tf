variable "name_prefix" {
  description = "Prefix for all resource names, e.g. saa-frontdesk."
  type        = string
}

variable "kms_key_arn" {
  description = "ARN of the shared CMK used to encrypt the artifact bucket."
  type        = string
}

variable "tags" {
  description = "Tags applied to all resources."
  type        = map(string)
  default     = {}
}

variable "github_org" {
  description = "GitHub organisation or user that owns the repo."
  type        = string
  default     = "hyferdev"
}

variable "github_repo" {
  description = "GitHub repository name."
  type        = string
  default     = "aws_saa-lab"
}

variable "github_branch" {
  description = "Branch that triggers the pipeline."
  type        = string
  default     = "main"
}

variable "ecr_repository_url" {
  description = "Full URI of the ECR repository (without tag). Passed to CodeBuild as ECR_REPO_URI."
  type        = string
}

variable "ecr_repository_arn" {
  description = "ARN of the ECR repository, used to scope CodeBuild push permissions."
  type        = string
}

variable "ecs_cluster_name" {
  description = "Name of the ECS cluster to deploy into."
  type        = string
}

variable "ecs_service_name" {
  description = "Name of the ECS service to update on deploy."
  type        = string
}
