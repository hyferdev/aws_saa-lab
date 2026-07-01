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

variable "asg_name" {
  description = "Name of the Auto Scaling Group that CodeDeploy deploys into."
  type        = string
}

variable "alb_target_group_name" {
  description = "Name of the ALB target group used for in-place traffic control."
  type        = string
}

variable "instance_role_name" {
  description = "Name of the EC2 instance IAM role — pipeline attaches artifact-read policy here."
  type        = string
}
