output "shared_kms_key_arn" {
  description = "ARN of the shared CMK."
  value       = module.foundation.kms_key_arn
}

output "frontdesk_assets_bucket" {
  description = "Name of the frontdesk assets bucket."
  value       = module.frontdesk.assets_bucket_id
}

output "frontdesk_instance_profile" {
  description = "Instance profile name for frontdesk EC2 instances."
  value       = module.frontdesk.instance_profile_name
}
