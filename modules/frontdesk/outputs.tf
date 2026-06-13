output "assets_bucket_id" {
  description = "Name of the frontdesk assets S3 bucket."
  value       = module.assets_bucket.bucket_id
}

output "assets_bucket_arn" {
  description = "ARN of the frontdesk assets S3 bucket."
  value       = module.assets_bucket.bucket_arn
}

output "instance_profile_name" {
  description = "Instance profile name to attach to EC2 launch templates."
  value       = module.instance_role.instance_profile_name
}

output "instance_role_arn" {
  description = "ARN of the frontdesk EC2 instance role."
  value       = module.instance_role.role_arn
}
