variable "name" {
  description = "Name of the ECR repository."
  type        = string
}

variable "kms_key_arn" {
  description = "ARN of the CMK used to encrypt images at rest."
  type        = string
}

variable "tags" {
  description = "Tags applied to all resources."
  type        = map(string)
  default     = {}
}
