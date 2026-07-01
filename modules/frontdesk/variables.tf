variable "name_prefix" {
  description = "Prefix for all resource names, e.g. saa-frontdesk."
  type        = string
}

variable "kms_key_arn" {
  description = "ARN of the shared CMK from the foundation module."
  type        = string
}

variable "vpc_id" {
  description = "VPC in which to place compute resources."
  type        = string
}

variable "public_subnet_ids" {
  description = "Public subnet IDs for the ALB."
  type        = list(string)
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for ECS tasks."
  type        = list(string)
}

variable "task_cpu" {
  description = "Fargate task CPU units (256 = 0.25 vCPU)."
  type        = number
  default     = 256
}

variable "task_memory" {
  description = "Fargate task memory in MiB."
  type        = number
  default     = 512
}

variable "desired_count" {
  description = "Desired number of running ECS tasks."
  type        = number
  default     = 1
}

variable "tags" {
  description = "Tags merged with the App tag and applied to all resources."
  type        = map(string)
  default     = {}
}
