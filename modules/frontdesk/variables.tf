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
  description = "Private subnet IDs for the ASG instances."
  type        = list(string)
}

variable "instance_type" {
  description = "EC2 instance type for the ASG launch template."
  type        = string
  default     = "t3.micro"
}

variable "asg_min" {
  description = "Minimum number of instances in the ASG."
  type        = number
  default     = 1
}

variable "asg_max" {
  description = "Maximum number of instances in the ASG."
  type        = number
  default     = 3
}

variable "asg_desired" {
  description = "Desired number of instances in the ASG."
  type        = number
  default     = 1
}

variable "tags" {
  description = "Tags merged with the App tag and applied to all resources."
  type        = map(string)
  default     = {}
}
