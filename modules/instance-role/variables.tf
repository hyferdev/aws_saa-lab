variable "name" {
  description = "Name for the IAM role and instance profile."
  type        = string
}

variable "policy_json" {
  description = "Inline permissions policy document (JSON) scoped to this app's resources."
  type        = string
}

variable "tags" {
  description = "Tags applied to the role and instance profile."
  type        = map(string)
  default     = {}
}
