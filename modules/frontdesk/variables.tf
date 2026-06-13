variable "name_prefix" {
  description = "Prefix for all resource names, e.g. saa-frontdesk."
  type        = string
}

variable "kms_key_arn" {
  description = "ARN of the shared CMK from the foundation module."
  type        = string
}

variable "tags" {
  description = "Tags merged with the App tag and applied to all resources."
  type        = map(string)
  default     = {}
}
