output "shared_kms_key_arn" {
  description = "ARN of the shared CMK."
  value       = module.foundation.kms_key_arn
}

output "vpc_id" {
  description = "ID of the shared VPC."
  value       = module.network.vpc_id
}

output "public_subnet_ids" {
  description = "Public subnet IDs (ordered a, b)."
  value       = module.network.public_subnet_ids
}

output "private_subnet_ids" {
  description = "Private subnet IDs (ordered a, b)."
  value       = module.network.private_subnet_ids
}

output "ssm_probe_instance_id" {
  description = "Sprint 3 SSM probe instance ID. Remove in sprint 4."
  value       = aws_instance.ssm_probe.id
}

output "frontdesk_assets_bucket" {
  description = "Name of the frontdesk assets bucket."
  value       = module.frontdesk.assets_bucket_id
}

output "frontdesk_instance_profile" {
  description = "Instance profile name for frontdesk EC2 instances."
  value       = module.frontdesk.instance_profile_name
}
