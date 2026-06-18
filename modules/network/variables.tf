variable "name_prefix" {
  description = "Name prefix for all resources (e.g. saa-shared)."
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnets" {
  description = "Map of public subnets. Key becomes part of the resource name."
  type = map(object({
    cidr = string
    az   = string
  }))
  default = {
    a = { cidr = "10.0.0.0/24", az = "us-east-1a" }
    b = { cidr = "10.0.1.0/24", az = "us-east-1b" }
  }
}

variable "private_subnets" {
  description = "Map of private subnets. Key becomes part of the resource name."
  type = map(object({
    cidr = string
    az   = string
  }))
  default = {
    a = { cidr = "10.0.10.0/24", az = "us-east-1a" }
    b = { cidr = "10.0.11.0/24", az = "us-east-1b" }
  }
}

variable "nat_az" {
  description = "Key of the public subnet in which to place the NAT Gateway."
  type        = string
  default     = "a"
}

variable "flow_logs_retention_days" {
  description = "CloudWatch log retention in days for VPC flow logs."
  type        = number
  default     = 30
}

variable "tags" {
  description = "Tags merged onto all resources."
  type        = map(string)
  default     = {}
}
